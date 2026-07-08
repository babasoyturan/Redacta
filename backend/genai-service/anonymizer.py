from dotenv import load_dotenv
import os
import re
from typing import Annotated, Literal, List
from pydantic import BaseModel,RootModel
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langchain.chat_models import init_chat_model
from local_fallback import uses_local_fallback

load_dotenv()

OPENAI_MODEL = os.getenv("GENAI_OPENAI_MODEL", "gpt-4.1-mini")
_llm = None


def get_llm():
    global _llm
    if _llm is None:
        _llm = init_chat_model(f"openai:{OPENAI_MODEL}")
    return _llm

class ChangedTerm(TypedDict):
    original: str
    anonymized: str

class AnonymizerState(TypedDict):
    messages: Annotated[list, add_messages]
    level: Literal["light", "medium", "high"]
    changed_terms: list[ChangedTerm] | None

class ChangedTermsResponse(BaseModel):  
    changed_terms: List[ChangedTerm]


def _extract_terms_locally(text: str, level: str) -> list[ChangedTerm]:
    terms: list[ChangedTerm] = []
    seen: set[str] = set()
    counters: dict[str, int] = {}

    def add(original: str, label: str) -> None:
        original = original.strip(" ,.;:()[]{}")
        if len(original) < 3 or original in seen:
            return
        seen.add(original)
        counters[label] = counters.get(label, 0) + 1
        terms.append({"original": original, "anonymized": f"[{label.upper()}_{counters[label]}]"})

    for match in re.finditer(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b", text):
        add(match.group(0), "email")

    for match in re.finditer(r"(?:\+?\d[\d\s().-]{7,}\d)", text):
        add(match.group(0), "phone")

    if level in {"medium", "high"}:
        for match in re.finditer(r"\b(?:https?://)?(?:www\.)?(?:linkedin|github)\.com/[^\s,;]+", text, re.IGNORECASE):
            add(match.group(0), "url")

        for match in re.finditer(r"\b[A-Z][a-z]+(?:[_\s]+[A-Z][a-z]+){1,2}\b", text):
            add(match.group(0), "person")

        for match in re.finditer(r"\b(?:Baki|Baku|Azerbaycan|Azerbaijan)\b", text, re.IGNORECASE):
            add(match.group(0), "location")

    if level == "high":
        for match in re.finditer(r"\b(?:19|20)\d{2}\b|\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b", text):
            add(match.group(0), "date")

    return terms


def extract_terms(state: AnonymizerState):
    user_msg = state["messages"][-1]
    level = state["level"]

    if uses_local_fallback():
        return {"changed_terms": _extract_terms_locally(user_msg.content, level)}

    structured_llm = get_llm().with_structured_output(ChangedTermsResponse)

    level_prompt_map = {
        "light": "Extract a list of names to anonymize. Replace each with a generic label like 'Person A'.",
        "medium": "Extract a list of names, dates, locations. Replace with generic labels like 'Person A', 'Date A', etc.",
        "high": "Extract names, dates, locations, genders, professions, and identifying info. Replace with 'Person A', 'Location B', etc."
    }

    system_prompt = (
        f"You are an anonymization assistant. "
        f"{level_prompt_map[level]} "
        "Respond with structured data only — a list of objects, each with `original` and `anonymized` fields."
    )

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_msg.content}
    ]

    changed_terms = structured_llm.invoke(messages).changed_terms

    return {"changed_terms": changed_terms}

# Build graph with single node
graph_builder = StateGraph(AnonymizerState)

graph_builder.add_node("extract_terms", extract_terms)

graph_builder.add_edge(START, "extract_terms")
graph_builder.add_edge("extract_terms", END)

graph = graph_builder.compile()

