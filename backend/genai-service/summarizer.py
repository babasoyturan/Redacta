from dotenv import load_dotenv
from typing import Annotated, Literal
import os
from pydantic import BaseModel
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langchain.chat_models import init_chat_model
from local_fallback import summarize_text, uses_local_fallback

load_dotenv()

OPENAI_MODEL = os.getenv("GENAI_OPENAI_MODEL", "gpt-4.1-mini")
_llm = None


def get_llm():
    global _llm
    if _llm is None:
        _llm = init_chat_model(f"openai:{OPENAI_MODEL}")
    return _llm

class SummarizerState(TypedDict):
    messages: Annotated[list, add_messages]
    level: Literal["short", "medium", "long"]
    summarized_text: str | None

def summarize(state: SummarizerState):
    user_msg = state["messages"][-1]
    level = state["level"]

    if uses_local_fallback():
        return {"summarized_text": summarize_text(user_msg.content, level)}

    level_prompt_map = {
        "short": "Provide a short summary of the following text",
        "medium": "Provide a medium-length summary of the text",
        "long": "Provide a detailed summary covering all major points in multiple paragraphs."
    }

    system_prompt = f"You are a summarization assistant. {level_prompt_map[level]}"

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_msg.content}
    ]

    reply = get_llm().invoke(messages)
    return {"summarized_text": reply.content}

# Build graph with single node
graph_builder = StateGraph(SummarizerState)

graph_builder.add_node("summarize", summarize)

graph_builder.add_edge(START, "summarize")
graph_builder.add_edge("summarize", END)

graph = graph_builder.compile()

