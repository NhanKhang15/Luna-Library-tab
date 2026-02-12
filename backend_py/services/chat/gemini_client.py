"""
Gemini API client - wraps REST API calls to Google Generative AI.
"""

import os
import requests
from dotenv import load_dotenv

load_dotenv()

GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
GEMINI_MODEL = "gemini-flash-latest"

SYSTEM_INSTRUCTION = """Bạn là một trợ lý sức khỏe thân thiện và chuyên nghiệp, chuyên về chu kỳ kinh nguyệt và sức khỏe sinh sản nữ giới. 

Nguyên tắc của bạn:
- Trả lời bằng tiếng Việt, giọng ấm áp, gần gũi, dễ hiểu
- Đưa ra thông tin chính xác dựa trên kiến thức y khoa
- Khi có dữ liệu từ thư viện bài viết/video, hãy tham khảo và gợi ý nội dung phù hợp
- Không chẩn đoán bệnh, luôn khuyên người dùng gặp bác sĩ nếu có triệu chứng nghiêm trọng
- Sử dụng emoji phù hợp để tạo cảm giác thân thiện
- Trả lời ngắn gọn, tập trung vào câu hỏi"""


class GeminiClient:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY", "")
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY not set in .env")

    def generate(
        self,
        user_message: str,
        history: list[dict] | None = None,
        db_context: str = "",
    ) -> str:
        """
        Call Gemini API with conversation history and database context.
        
        Args:
            user_message: Current user message
            history: List of {"role": "user"|"model", "text": "..."} dicts
            db_context: Relevant content from database (RAG)
        
        Returns:
            AI response text
        """
        url = f"{GEMINI_BASE_URL}/models/{GEMINI_MODEL}:generateContent?key={self.api_key}"

        # Build contents array from history
        contents = []

        if history:
            for msg in history:
                contents.append({
                    "role": msg["role"],
                    "parts": [{"text": msg["text"]}]
                })

        # Build current user message with optional DB context
        user_text = user_message
        if db_context:
            user_text = (
                f"{user_message}\n\n"
                f"[Dữ liệu tham khảo từ thư viện]\n{db_context}"
            )

        contents.append({
            "role": "user",
            "parts": [{"text": user_text}]
        })

        payload = {
            "system_instruction": {
                "parts": [{"text": SYSTEM_INSTRUCTION}]
            },
            "contents": contents,
            "generationConfig": {
                "temperature": 0.7,
                "topP": 0.9,
                "maxOutputTokens": 1024,
            }
        }

        response = requests.post(
            url,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30,
        )

        if response.status_code != 200:
            error_detail = response.text
            raise Exception(f"Gemini API error {response.status_code}: {error_detail}")

        data = response.json()

        # Extract text from response
        try:
            return data["candidates"][0]["content"]["parts"][0]["text"]
        except (KeyError, IndexError):
            raise Exception(f"Unexpected Gemini response format: {data}")
