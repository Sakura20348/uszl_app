"""Checks Google / Apple ID tokens sent by the app after the user signs in with them."""

from dataclasses import dataclass
from typing import Literal

import jwt
from jwt import PyJWKClient

from app.core.config import get_settings

Provider = Literal["google", "apple"]

_PROVIDERS = {
    "google": ("https://www.googleapis.com/oauth2/v3/certs", ["https://accounts.google.com", "accounts.google.com"]),
    "apple": ("https://appleid.apple.com/auth/keys", ["https://appleid.apple.com"]),
}
_key_clients: dict[str, PyJWKClient] = {}


@dataclass
class SocialIdentity:
    uid: str
    email: str | None
    name: str | None


class SocialAuthError(Exception):
    pass


def verify_id_token(provider: Provider, id_token: str) -> SocialIdentity:
    """Raises SocialAuthError if the provider is off or the token is not valid for our app."""
    settings = get_settings()
    audiences = settings.google_client_ids if provider == "google" else settings.apple_client_ids
    if not audiences:
        raise SocialAuthError(f"{provider.title()} sign-in is not set up on the server")

    keys_url, issuers = _PROVIDERS[provider]
    client = _key_clients.setdefault(provider, PyJWKClient(keys_url, cache_keys=True))
    try:
        key = client.get_signing_key_from_jwt(id_token)
        claims = jwt.decode(id_token, key.key, algorithms=["RS256"], audience=audiences, issuer=issuers)
    except jwt.PyJWTError as e:
        raise SocialAuthError(f"Invalid {provider} token") from e

    email = claims.get("email")
    if email and claims.get("email_verified") in (False, "false"):
        email = None
    return SocialIdentity(uid=str(claims["sub"]), email=email, name=claims.get("name"))
