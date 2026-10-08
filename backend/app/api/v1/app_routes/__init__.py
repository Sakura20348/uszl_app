"""Routes for the mobile app. Content is public; everything personal needs login."""

from fastapi import APIRouter

from app.api.v1.app_routes import community, config, dictionary, learning, profile

router = APIRouter()
router.include_router(profile.router)
router.include_router(dictionary.router)
router.include_router(learning.router)
router.include_router(community.router)
router.include_router(config.router)
