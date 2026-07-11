# ABOUTME: This module manages uploaded document chunks for retrieval.
# ABOUTME: It avoids an external vector database so the service remains lightweight in Kubernetes.

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import hashlib
import re

from pypdf import PdfReader


@dataclass
class TextChunk:
    page_content: str
    metadata: Dict = field(default_factory=dict)


class SimpleRetriever:
    def __init__(
        self,
        vector_store: "VectorStoreManager",
        k: int,
        document_ids: Optional[List[str]],
    ):
        self.vector_store = vector_store
        self.k = k
        self.document_ids = document_ids

    def invoke(self, query: str) -> List[TextChunk]:
        return self.vector_store.search_documents(
            query=query, k=self.k, document_ids=self.document_ids
        )

    def get_relevant_documents(self, query: str) -> List[TextChunk]:
        return self.invoke(query)


class VectorStoreManager:
    def __init__(self, persist_directory: str = "./document_store"):
        self.persist_directory = Path(persist_directory)
        self.persist_directory.mkdir(parents=True, exist_ok=True)
        self.chunk_size = 1000
        self.chunk_overlap = 200
        self.documents: Dict[str, List[TextChunk]] = {}
        self.document_metadata: Dict[str, Dict] = {}

    def generate_document_id(self, filename: str, content: bytes) -> str:
        content_hash = hashlib.sha256(content).hexdigest()[:12]
        return f"{Path(filename).stem}_{content_hash}"

    def ingest_pdf(
        self, file_path: str, filename: str, document_id: Optional[str] = None
    ) -> Tuple[str, int]:
        content = Path(file_path).read_bytes()
        if not document_id:
            document_id = self.generate_document_id(filename, content)

        reader = PdfReader(file_path)
        page_chunks: List[TextChunk] = []

        for page_number, page in enumerate(reader.pages, start=1):
            page_text = page.extract_text() or ""
            if page_text.strip():
                page_chunks.append(
                    TextChunk(
                        page_content=page_text,
                        metadata={"source": filename, "page": page_number},
                    )
                )

        if not page_chunks:
            raise ValueError(f"PDF contains no readable text: {filename}")

        chunks = self._split_documents(page_chunks)
        if not chunks:
            raise ValueError(
                f"No text chunks could be created from PDF: {filename}"
            )

        self._store_chunks(
            document_id=document_id,
            filename=filename,
            file_type="pdf",
            chunks=chunks,
        )
        return document_id, len(chunks)

    def ingest_markdown(
        self, content: str, filename: str, document_id: Optional[str] = None
    ) -> Tuple[str, int]:
        if not content.strip():
            raise ValueError(f"Markdown content is empty: {filename}")

        if not document_id:
            document_id = self.generate_document_id(filename, content.encode())

        chunks = self._split_text(
            content, metadata={"source": filename, "file_type": "markdown"}
        )
        self._store_chunks(
            document_id=document_id,
            filename=filename,
            file_type="markdown",
            chunks=chunks,
        )
        return document_id, len(chunks)

    def ingest_text(
        self,
        content: str,
        title: str = "Untitled Text",
        document_id: Optional[str] = None,
        metadata: Optional[Dict] = None,
    ) -> Tuple[str, int]:
        if not content.strip():
            raise ValueError(f"Text content is empty: {title}")

        if not document_id:
            document_id = self.generate_document_id(title, content.encode())

        doc_metadata = {"source": title, "file_type": "text"}
        if metadata:
            doc_metadata.update(metadata)

        chunks = self._split_text(content, metadata=doc_metadata)
        self._store_chunks(
            document_id=document_id,
            filename=title,
            file_type="text",
            chunks=chunks,
            extra_metadata=metadata,
        )
        return document_id, len(chunks)

    def search_documents(
        self, query: str, k: int = 5, document_ids: Optional[List[str]] = None
    ) -> List[TextChunk]:
        selected_ids = document_ids or list(self.documents.keys())
        chunks: List[TextChunk] = []
        for document_id in selected_ids:
            chunks.extend(self.documents.get(document_id, []))

        if not chunks:
            return []

        terms = set(re.findall(r"\w+", query.lower()))
        if not terms:
            return chunks[:k]

        scored = []
        for index, chunk in enumerate(chunks):
            text = chunk.page_content.lower()
            score = sum(text.count(term) for term in terms)
            scored.append((score, index, chunk))

        scored.sort(key=lambda item: (-item[0], item[1]))
        return [chunk for _, _, chunk in scored[:k]]

    def get_retriever(
        self, k: int = 5, document_ids: Optional[List[str]] = None
    ) -> SimpleRetriever:
        return SimpleRetriever(self, k=k, document_ids=document_ids)

    def list_documents(self) -> List[Dict]:
        return [
            {"document_id": doc_id, **metadata}
            for doc_id, metadata in self.document_metadata.items()
        ]

    def delete_document(self, document_id: str) -> bool:
        self.documents.pop(document_id, None)
        return self.document_metadata.pop(document_id, None) is not None

    def _store_chunks(
        self,
        document_id: str,
        filename: str,
        file_type: str,
        chunks: List[TextChunk],
        extra_metadata: Optional[Dict] = None,
    ) -> None:
        upload_time = datetime.utcnow().isoformat()
        total_chunks = len(chunks)

        for index, chunk in enumerate(chunks):
            chunk.metadata.update(
                {
                    "document_id": document_id,
                    "filename": filename,
                    "chunk_index": index,
                    "total_chunks": total_chunks,
                    "upload_time": upload_time,
                    "file_type": file_type,
                }
            )

        self.documents[document_id] = chunks
        self.document_metadata[document_id] = {
            "filename": filename,
            "file_type": file_type,
            "total_chunks": total_chunks,
            "upload_time": upload_time,
            **(extra_metadata or {}),
        }

    def _split_documents(self, documents: List[TextChunk]) -> List[TextChunk]:
        chunks: List[TextChunk] = []
        for document in documents:
            chunks.extend(
                self._split_text(document.page_content, metadata=document.metadata)
            )
        return chunks

    def _split_text(self, text: str, metadata: Optional[Dict] = None) -> List[TextChunk]:
        normalized = "\n".join(
            line.strip() for line in text.splitlines() if line.strip()
        )
        if not normalized:
            return []

        chunks: List[TextChunk] = []
        start = 0

        while start < len(normalized):
            end = min(start + self.chunk_size, len(normalized))
            if end < len(normalized):
                boundary = max(
                    normalized.rfind(separator, start, end)
                    for separator in ("\n\n", "\n", ". ", "! ", "? ", " ")
                )
                if boundary > start + self.chunk_size // 2:
                    end = boundary + 1

            chunk_text = normalized[start:end].strip()
            if chunk_text:
                chunks.append(
                    TextChunk(
                        page_content=chunk_text,
                        metadata=dict(metadata or {}),
                    )
                )

            if end >= len(normalized):
                break

            next_start = max(end - self.chunk_overlap, 0)
            start = next_start if next_start > start else end

        return chunks
