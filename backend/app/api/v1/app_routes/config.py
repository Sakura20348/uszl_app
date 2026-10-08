from fastapi import APIRouter

from app.deps import DB
from app.models import AppConfig
from app.schemas.config import AppConfigOut

router = APIRouter()


async def load_config(db: DB) -> AppConfigOut:
    """The saved settings, with defaults for anything not set yet."""
    config = await db.get(AppConfig, 1)
    if config is None:
        return AppConfigOut()
    return AppConfigOut.model_validate({**config.data, "updatedAt": config.updated_at})


@router.get("/config", response_model=AppConfigOut, tags=["app settings"])
async def app_config(db: DB) -> AppConfigOut:
    """Public (also before login): sections on/off, maintenance, minimum versions, support contacts."""
    return await load_config(db)
