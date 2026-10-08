"""Routes for the admin dashboard; every route needs a staff account (users.is_staff)."""

from fastapi import APIRouter, Depends

from app.api.v1.admin_routes import app_config, community, dictionary, learning, users
from app.deps import get_staff

router = APIRouter(dependencies=[Depends(get_staff)])
router.include_router(users.router)
router.include_router(dictionary.router)
router.include_router(learning.router)
router.include_router(community.router)
router.include_router(app_config.router)
