from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://uzsl:uzsl@localhost:5432/uzsl"

    jwt_secret: str = "change-me"
    access_token_minutes: int = 60
    refresh_token_days: int = 30

    cors_origins: list[str] = [
        "http://localhost:5173",  # Vite dashboard (dev)
        "http://localhost:4173",  # Vite dashboard (preview)
        "https://admin.uzsl.uz",
    ]

    # SMS provider for login codes: "" (none) or "eskiz" (notify.eskiz.uz)
    sms_provider: str = ""
    eskiz_email: str = ""
    eskiz_password: str = ""
    # Sender name; "4546" is Eskiz's default until your own is approved
    eskiz_from: str = "4546"
    eskiz_base_url: str = "https://notify.eskiz.uz/api"
    # Text of the login SMS; {code} is replaced. Eskiz only sends texts approved as templates in your
    # Eskiz account (until then only their test text works).
    sms_otp_template: str = "UzSL: tasdiqlash kodi {code}"

    # SMS login codes. There is no SMS provider yet: with otp_debug the code is
    # printed to the server log and returned in the response, so you can log in while developing.
    otp_debug: bool = True
    otp_length: int = 6
    otp_ttl_minutes: int = 5
    otp_max_attempts: int = 5

    # Uploaded lesson videos and images, served at /media
    media_dir: str = "media"
    max_upload_mb: int = 50

    # Google / Apple sign-in: the app's OAuth client ids (ID tokens must be issued for one of them).
    # Empty = that provider is turned off.
    google_client_ids: list[str] = []
    apple_client_ids: list[str] = []

    # Firebase Authentication: the app signs in with Firebase (email/password) and trades the
    # Firebase ID token for this API's tokens at POST /auth/firebase
    firebase_project_id: str = "uzsl-7cd39"

    # Push notifications (Firebase Cloud Messaging): path to the Firebase service account key
    # (Firebase console > Project settings > Service accounts > Generate new private key).
    # Empty = push is off; notifications still show inside the app.
    fcm_credentials_file: str = ""
    fcm_api_url: str = "https://fcm.googleapis.com"
    # Must match the channel the app creates (lib/services/push_service.dart)
    fcm_android_channel: str = "uzsl_default"

    # A user counts as "online" if they used the app this recently
    online_minutes: int = 5
    # Lesson accuracy (%) needed to complete a lesson
    lesson_pass_accuracy: int = 50
    # XP needed for each level
    xp_per_level: int = 100


@lru_cache
def get_settings() -> Settings:
    return Settings()
