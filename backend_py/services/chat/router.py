"""
Chat router - FastAPI endpoints for Gemini AI chat with RAG context.
"""

from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from .gemini_client import GeminiClient
from .db_context import get_relevant_content


router = APIRouter()


class ChatMessage(BaseModel):
    role: str  # "user" or "model"
    text: str


class ChatRequest(BaseModel):
    message: str
    history: Optional[list[ChatMessage]] = None


class ChatResponse(BaseModel):
    reply: str


# Lazy-init client (fails gracefully if no API key)
_client: GeminiClient | None = None


def _get_client() -> GeminiClient:
    global _client
    if _client is None:
        _client = GeminiClient()
    return _client


@router.post("/send", response_model=ChatResponse)
async def send_message(req: ChatRequest):
    """
    Send a message to the AI assistant.
    Retrieves relevant content from the database and sends it as context.
    """
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")

    try:
        # 1. Get relevant content from database
        db_context = get_relevant_content(req.message)

        # 2. Convert history to dict format
        history = None
        if req.history:
            history = [{"role": m.role, "text": m.text} for m in req.history]

        # 3. Call Gemini with context
        client = _get_client()
        reply = client.generate(
            user_message=req.message,
            history=history,
            db_context=db_context,
        )

        return ChatResponse(reply=reply)

    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")
