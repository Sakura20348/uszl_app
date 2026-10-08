"""Sending SMS (login codes) through Eskiz.uz: https://notify.eskiz.uz/api

Settings: SMS_PROVIDER=eskiz, ESKIZ_EMAIL, ESKIZ_PASSWORD, ESKIZ_FROM, SMS_OTP_TEMPLATE.
"""

import asyncio
import logging

import httpx

from app.core.config import get_settings

log = logging.getLogger("uvicorn.error")


class SmsError(Exception):
    pass


class EskizClient:
    def __init__(self) -> None:
        self._token: str | None = None
        self._lock = asyncio.Lock()

    async def _login(self, client: httpx.AsyncClient) -> str:
        settings = get_settings()
        response = await client.post(
            f"{settings.eskiz_base_url}/auth/login",
            data={"email": settings.eskiz_email, "password": settings.eskiz_password},
        )
        token = response.json().get("data", {}).get("token") if response.status_code == 200 else None
        if not token:
            raise SmsError(f"Eskiz login failed ({response.status_code}): {response.text[:200]}")
        return token

    async def _refresh(self, client: httpx.AsyncClient, old: str) -> str:
        """New token: refresh the old one (tokens last about 30 days), or log in again."""
        async with self._lock:
            if self._token and self._token != old:
                return self._token  # another request already renewed it
            try:
                response = await client.patch(
                    f"{get_settings().eskiz_base_url}/auth/refresh", headers={"Authorization": f"Bearer {old}"}
                )
                token = response.json().get("data", {}).get("token") if response.status_code == 200 else None
            except (httpx.HTTPError, ValueError):
                token = None
            self._token = token or await self._login(client)
            return self._token

    async def send(self, phone: str, text: str) -> None:
        settings = get_settings()
        body = {"mobile_phone": phone.lstrip("+"), "message": text, "from": settings.eskiz_from}
        async with httpx.AsyncClient(timeout=15) as client:
            try:
                if self._token is None:
                    async with self._lock:
                        if self._token is None:
                            self._token = await self._login(client)
                token = self._token
                url = f"{settings.eskiz_base_url}/message/sms/send"
                response = await client.post(url, data=body, headers={"Authorization": f"Bearer {token}"})
                if response.status_code == 401:
                    token = await self._refresh(client, token)
                    response = await client.post(url, data=body, headers={"Authorization": f"Bearer {token}"})
            except httpx.HTTPError as e:
                raise SmsError(f"Eskiz unreachable: {e}") from e
        if response.status_code not in (200, 201):
            # E.g. the text is not an approved template, or the balance is empty
            raise SmsError(f"Eskiz refused the SMS ({response.status_code}): {response.text[:300]}")


_eskiz = EskizClient()


def sms_enabled() -> bool:
    settings = get_settings()
    return settings.sms_provider == "eskiz" and bool(settings.eskiz_email and settings.eskiz_password)


async def send_login_code(phone: str, code: str) -> None:
    """Raises SmsError if the SMS could not be sent."""
    text = get_settings().sms_otp_template.replace("{code}", code)
    await _eskiz.send(phone, text)
    log.info("Login SMS sent to %s***", phone[:7])
