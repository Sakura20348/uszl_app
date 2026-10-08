import re
from typing import Literal

from pydantic import EmailStr, Field, field_validator, model_validator

from app.schemas.common import Schema

OtpPurpose = Literal["login", "reset_password"]


def normalize_phone(value: str) -> str:
    """"90 123 45 67", "+998 90 123-45-67" -> "+998901234567"."""
    digits = re.sub(r"\D", "", value)
    if len(digits) == 9:
        digits = "998" + digits
    if not (len(digits) == 12 and digits.startswith("998")):
        raise ValueError("Enter an Uzbek phone number: +998 XX XXX XX XX")
    return "+" + digits


class PhoneIn(Schema):
    phone: str

    @field_validator("phone")
    @classmethod
    def _phone(cls, v: str) -> str:
        return normalize_phone(v)


class OtpRequestIn(PhoneIn):
    # login: log in, or sign up if the number is new. reset_password: set a new password.
    purpose: OtpPurpose = "login"


class OtpSentOut(Schema):
    expires_in: int
    # Only in development (OTP_DEBUG), while no SMS provider is connected
    debug_code: str | None = None


class OtpVerifyIn(PhoneIn):
    code: str = Field(pattern=r"^\d{4,8}$")


class PasswordLoginIn(Schema):
    """Log in with a phone number or an email, and the password."""

    phone: str | None = None
    email: EmailStr | None = None
    password: str = Field(max_length=128)

    @field_validator("phone")
    @classmethod
    def _phone(cls, v: str | None) -> str | None:
        return normalize_phone(v) if v else None

    @model_validator(mode="after")
    def _one_login(self) -> "PasswordLoginIn":
        if bool(self.phone) == bool(self.email):
            raise ValueError("Send either phone or email")
        return self


class EmailRegisterIn(Schema):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str | None = Field(default=None, max_length=150)


class PasswordResetIn(OtpVerifyIn):
    new_password: str = Field(min_length=8, max_length=128)


class PasswordChangeIn(Schema):
    # Not needed if the account has no password yet
    old_password: str | None = Field(default=None, max_length=128)
    new_password: str = Field(min_length=8, max_length=128)


class SocialLoginIn(Schema):
    provider: Literal["google", "apple"]
    id_token: str = Field(min_length=10)
    # Apple sends the name only to the app, the first time
    full_name: str | None = Field(default=None, max_length=150)


class FirebaseLoginIn(Schema):
    # FirebaseAuth.instance.currentUser.getIdToken() in the app
    id_token: str = Field(min_length=10)
    # Shown in the dashboard; sent when signing up
    full_name: str | None = Field(default=None, max_length=150)


class RefreshIn(Schema):
    refresh_token: str


class TokenOut(Schema):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    # True when the account was just created, so the app can show onboarding
    is_new_user: bool = False
