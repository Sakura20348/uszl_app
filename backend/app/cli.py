"""Admin accounts:

    uv run python -m app.cli create-admin --phone 901234567 --email me@example.com --password 'at-least-8-chars' [--superuser]
    uv run python -m app.cli make-admin --phone 901234567 [--superuser]      (or --email)
    uv run python -m app.cli revoke-admin --email me@example.com             (or --phone)

create-admin also updates an existing account: give its phone or email, and the other one to add it.
An admin (is_staff) can use the dashboard; a superuser can also manage other admins.
Without --password the admin logs in with an SMS code (needs --phone).
"""

import argparse
import asyncio
import sys

from sqlalchemy import or_, select

from app.core.security import hash_password
from app.db import SessionLocal
from app.models import User
from app.progress import get_notification_settings, get_stats
from app.schemas.auth import normalize_phone


async def _find(db, phone: str | None, email: str | None) -> User | None:
    # Only compare the values that were given: `User.email == None` would match every account without an email
    conditions = [c for c, given in ((User.phone == phone, phone), (User.email == email, email)) if given]
    matches = list(await db.scalars(select(User).where(or_(*conditions))))
    if len(matches) > 1:
        sys.exit(f"{phone} and {email} belong to two different accounts (ids {[u.id for u in matches]})")
    return matches[0] if matches else None


async def create_admin(phone: str | None, email: str | None, password: str | None, name: str, superuser: bool) -> None:
    async with SessionLocal() as db:
        user = await _find(db, phone, email)
        if user is None:
            user = User(phone=phone, email=email, full_name=name)
            db.add(user)
            await db.flush()
            await get_notification_settings(db, user.id)
            await get_stats(db, user.id)
        user.phone = phone or user.phone
        user.email = email or user.email
        user.is_staff = True
        user.is_superuser = user.is_superuser or superuser
        if password:
            user.password = hash_password(password)
        if not user.password and not user.phone:
            sys.exit("An email-only admin needs --password")
        await db.commit()
        role = "superuser" if user.is_superuser else "admin"
        print(f"{role} ready (id {user.id}): phone={user.phone} email={user.email} password={'set' if user.password else 'none'}")


async def set_admin(phone: str | None, email: str | None, staff: bool, superuser: bool) -> None:
    async with SessionLocal() as db:
        user = await _find(db, phone, email)
        if user is None:
            sys.exit(f"No user with {phone or email}")
        user.is_staff = staff
        user.is_superuser = staff and (superuser or user.is_superuser)
        await db.commit()
        print(f"{phone or email}: is_staff={user.is_staff}, is_superuser={user.is_superuser}")


def main() -> None:
    parser = argparse.ArgumentParser(prog="python -m app.cli")
    commands = parser.add_subparsers(dest="command", required=True)
    create = commands.add_parser("create-admin", help="Create an admin, or update an existing account and make it one")
    make = commands.add_parser("make-admin", help="Give an existing account admin rights")
    revoke = commands.add_parser("revoke-admin", help="Take admin rights away")
    for cmd in (create, make, revoke):
        cmd.add_argument("--phone")
        cmd.add_argument("--email")
    for cmd in (create, make):
        cmd.add_argument("--superuser", action="store_true", help="Can also manage other admins")
    create.add_argument("--password", help="For phone/email + password login (min 8 characters)")
    create.add_argument("--name", default="Admin")

    args = parser.parse_args()
    if not (args.phone or args.email):
        parser.error("give --phone or --email (or both)")
    try:
        phone = normalize_phone(args.phone) if args.phone else None
    except ValueError as e:
        parser.error(str(e))
    email = args.email.strip().lower() if args.email else None
    if email and "@" not in email:
        parser.error("--email doesn't look like an email address")

    if args.command == "create-admin":
        if args.password is not None and len(args.password) < 8:
            parser.error("--password must be at least 8 characters")
        asyncio.run(create_admin(phone, email, args.password, args.name, args.superuser))
    elif args.command == "make-admin":
        asyncio.run(set_admin(phone, email, True, args.superuser))
    else:
        asyncio.run(set_admin(phone, email, False, False))


if __name__ == "__main__":
    main()
