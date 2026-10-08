"""Helpers shared by the routers."""

from typing import Any

from fastapi import APIRouter, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import Base
from app.deps import DB
from app.models import Sign, User
from app.schemas.common import Schema, media_url
from app.schemas.users import ProfileOut


async def get_or_404[T](db: AsyncSession, model: type[T], id_: Any, what: str | None = None) -> T:
    obj = await db.get(model, id_)
    if obj is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"{what or model.__name__} not found")
    return obj


def profile_out(user: User) -> ProfileOut:
    data = {c.key: getattr(user, c.key) for c in User.__table__.columns}
    return ProfileOut.model_validate({**data, "has_password": bool(user.password)})


def first_video(sign: Sign | None) -> str | None:
    """URL of a sign's main video (needs sign.videos loaded)."""
    if sign is None or not sign.videos:
        return None
    return media_url(sign.videos[0].video)


async def commit(db: AsyncSession) -> None:
    """Commits; a duplicate slug/code or a reference to a missing row becomes a 409/422 instead of a 500."""
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        code = getattr(e.orig, "sqlstate", None) or getattr(getattr(e.orig, "__cause__", None), "sqlstate", None)
        if code == "23505":
            raise HTTPException(status.HTTP_409_CONFLICT, "Already exists (a unique field is taken)") from None
        if code == "23503":
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Refers to a row that doesn't exist, or is still in use") from None
        raise


def crud_routes(
    router: APIRouter,
    path: str,
    model: type[Base],
    schema_in: type[Schema],
    schema_out: type[Schema],
    order_by: tuple[Any, ...],
    tag: str,
) -> None:
    """List / create / update / delete routes for a simple table."""
    name = model.__name__

    async def list_(db: DB) -> list[Any]:
        return list(await db.scalars(select(model).order_by(*order_by)))

    async def create(body: schema_in, db: DB) -> Any:  # type: ignore[valid-type]
        obj = model(**body.model_dump())  # type: ignore[attr-defined]
        db.add(obj)
        await commit(db)
        await db.refresh(obj)
        return obj

    async def update(item_id: int, body: schema_in, db: DB) -> Any:  # type: ignore[valid-type]
        obj = await get_or_404(db, model, item_id)
        for field, value in body.model_dump().items():  # type: ignore[attr-defined]
            setattr(obj, field, value)
        await commit(db)
        await db.refresh(obj)
        return obj

    async def delete(item_id: int, db: DB) -> Response:
        await db.delete(await get_or_404(db, model, item_id))
        await commit(db)
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    router.add_api_route(path, list_, methods=["GET"], response_model=list[schema_out], tags=[tag], name=f"list {name}")
    router.add_api_route(path, create, methods=["POST"], response_model=schema_out, status_code=201, tags=[tag], name=f"create {name}")
    router.add_api_route(f"{path}/{{item_id}}", update, methods=["PUT"], response_model=schema_out, tags=[tag], name=f"update {name}")
    router.add_api_route(f"{path}/{{item_id}}", delete, methods=["DELETE"], status_code=204, tags=[tag], name=f"delete {name}")
