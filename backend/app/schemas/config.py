"""Mobile app settings that admins control from the dashboard (Settings → App)."""

from datetime import datetime

from pydantic import EmailStr, Field

from app.schemas.common import Schema

VERSION = r"^\d+(\.\d+){0,2}$"


class AppSections(Schema):
    """Parts of the app that can be turned off for everyone."""

    dictionary: bool = True
    translator: bool = True
    # Recording sign videos for the dataset
    dataset: bool = True


class Maintenance(Schema):
    """While on, the app shows only this message (e.g. during a server update)."""

    enabled: bool = False
    message: str = Field(default="", max_length=500)


class AppVersions(Schema):
    """Older app versions ask the user to update from the store. Empty = no minimum."""

    android_min: str | None = Field(default=None, pattern=VERSION)
    ios_min: str | None = Field(default=None, pattern=VERSION)
    android_store_url: str | None = Field(default=None, max_length=300)
    ios_store_url: str | None = Field(default=None, max_length=300)


class SupportContacts(Schema):
    """Shown on the app's help / contact screen."""

    telegram: str | None = Field(default=None, max_length=100)
    phone: str | None = Field(default=None, max_length=30)
    email: EmailStr | None = None


class AppConfigIn(Schema):
    sections: AppSections = AppSections()
    maintenance: Maintenance = Maintenance()
    versions: AppVersions = AppVersions()
    support: SupportContacts = SupportContacts()


class AppConfigOut(AppConfigIn):
    # Empty until an admin saves the settings for the first time
    updated_at: datetime | None = None
