from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.v1 import auth, app_routes, admin_routes
from app.core.config import get_settings

settings = get_settings()

# A public server (test SMS codes off) must not run with the example secret: anyone could forge logins
if not settings.otp_debug and settings.jwt_secret in ("", "change-me"):
    raise RuntimeError("Set JWT_SECRET to a long random value before running with OTP_DEBUG=false")

app = FastAPI(title="UzSL API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,  # Vite dashboard
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,         prefix="/api/v1/auth",  tags=["auth"])
app.include_router(app_routes.router,   prefix="/api/v1/app",   tags=["app"])
app.include_router(admin_routes.router, prefix="/api/v1/admin", tags=["admin"])

# Uploaded lesson videos and images
Path(settings.media_dir).mkdir(parents=True, exist_ok=True)
app.mount("/media", StaticFiles(directory=settings.media_dir), name="media")


@app.get("/", tags=["health"])
def root() -> dict[str, str]:
    # Opening the server address in a browser (e.g. from the phone) shows it is reachable
    return {"service": "UzSL API", "status": "ok", "docs": "/docs"}


@app.get("/health", tags=["health"])
def health() -> dict[str, str]:
    return {"status": "ok"}
