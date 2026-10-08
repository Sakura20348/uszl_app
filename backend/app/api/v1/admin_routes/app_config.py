from datetime import UTC, datetime

from fastapi import APIRouter

from app.api.v1.app_routes.config import load_config
from app.deps import DB, Staff
from app.models import AppConfig
from app.schemas.config import AppConfigIn, AppConfigOut

router = APIRouter()
TAG = "admin: app settings"


@router.get("/app-config", response_model=AppConfigOut, tags=[TAG])
async def get_app_config(db: DB) -> AppConfigOut:
    return await load_config(db)


@router.put("/app-config", response_model=AppConfigOut, tags=[TAG])
async def save_app_config(body: AppConfigIn, admin: Staff, db: DB) -> AppConfigOut:
    """Replaces all app settings; the app picks them up the next time it starts or comes back to the front."""
    config = await db.get(AppConfig, 1)
    if config is None:
        config = AppConfig(id=1)
        db.add(config)
    config.data = body.model_dump(mode="json")
    config.updated_by_id = admin.id
    config.updated_at = datetime.now(UTC)
    await db.commit()
    return await load_config(db)
