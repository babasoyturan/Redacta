import os
import re


def uses_local_fallback() -> bool:
    value = os.getenv("GENAI_LOCAL_FALLBACK", "").strip().lower()
    api_key = os.getenv("OPENAI_API_KEY", "").strip()
    return value in {"1", "true", "yes", "on"} or api_key in {"", "local-placeholder"}


def split_sentences(text: str) -> list[str]:
    cleaned = re.sub(r"\s+", " ", text or "").strip()
    if not cleaned:
        return []
    sentences = re.split(r"(?<=[.!?])\s+", cleaned)
    return [sentence.strip() for sentence in sentences if sentence.strip()]


def summarize_text(text: str, level: str = "medium") -> str:
    sentences = split_sentences(text)
    if not sentences:
        return "No document text was provided."

    limits = {"short": 2, "medium": 4, "long": 8}
    limit = limits.get(level, 4)
    selected = sentences[:limit]

    if level == "long" and len(sentences) > limit:
        selected.append(f"The document continues with {len(sentences) - limit} additional sentence(s).")

    return " ".join(selected)


def answer_chat(query: str, document: str = "", context: str = "") -> str:
    source = context or document
    if source:
        summary = summarize_text(source, "medium")
        return (
            "Local fallback response: I can help identify personal information "
            "without the external AI key. "
            f"Relevant document context: {summary} "
            f"Your question was: {query}"
        )
    return (
        "Local fallback response: the GenAI service is running, but no document "
        f"context was provided. Your question was: {query}"
    )
