import logging
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, HTTPException, Response, status
from sqlalchemy import select, update

from app.core.config import get_settings
from app.core.security import create_token, decode_token, generate_otp, hash_otp, hash_password, verify_password
from app.sms import SmsError, send_login_code, sms_enabled
from app.core.firebase_auth import FirebaseAuthError, verify_firebase_token
from app.core.social import SocialAuthError, verify_id_token
from app.deps import DB, CurrentUser, OptionalUser
from app.models import PhoneOtp, SocialAccount, User
from app.progress import get_notification_settings, get_stats
from app.schemas.auth import (
    EmailRegisterIn,
    FirebaseLoginIn,
    OtpRequestIn,
    OtpSentOut,
    OtpVerifyIn,
    PasswordChangeIn,
    PasswordLoginIn,
    PasswordResetIn,
    RefreshIn,
    SocialLoginIn,
    TokenOut,
)
from app.schemas.users import ProfileOut
from app.api.v1.common import profile_out

router = APIRouter()
log = logging.getLogger("uvicorn.error")

# A new code can be requested this often per phone number
RESEND_SECONDS = 60


async def _login(db: DB, user: User, is_new_user: bool = False) -> TokenOut:
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "This account is blocked")
    user.last_login = datetime.now(UTC)
    if is_new_user:
        # Every account gets its settings and stats rows up front
        await get_notification_settings(db, user.id)
        await get_stats(db, user.id)
    await db.commit()
    return TokenOut(
        access_token=create_token(user.id, "access"),
        refresh_token=create_token(user.id, "refresh"),
        is_new_user=is_new_user,
    )


async def _use_otp(db: DB, phone: str, code: str, purpose: str) -> None:
    """Checks the newest unused code and marks it used; raises if it's wrong."""
    otp = await db.scalar(
        select(PhoneOtp)
        .where(
            PhoneOtp.phone == phone,
            PhoneOtp.purpose == purpose,
            PhoneOtp.is_used.is_(False),
            PhoneOtp.expires_at > datetime.now(UTC),
        )
        .order_by(PhoneOtp.created_at.desc())
        .limit(1)
    )
    if otp is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "The code has expired, request a new one")
    otp.attempts += 1
    if otp.attempts > get_settings().otp_max_attempts:
        otp.is_used = True
        await db.commit()
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "Too many attempts, request a new code")
    if otp.code_hash != hash_otp(phone, code):
        await db.commit()
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Wrong code")
    otp.is_used = True


# ===== SMS codes =====
@router.post("/otp/request", response_model=OtpSentOut)
async def request_otp(body: OtpRequestIn, db: DB) -> OtpSentOut:
    settings = get_settings()
    if not settings.otp_debug and not sms_enabled():
        # Nobody would receive the code: say so instead of letting people wait
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "SMS login is not available yet, use email")
    now = datetime.now(UTC)

    last = await db.scalar(
        select(PhoneOtp).where(PhoneOtp.phone == body.phone).order_by(PhoneOtp.created_at.desc()).limit(1)
    )
    if last and now - last.created_at < timedelta(seconds=RESEND_SECONDS):
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "Wait a minute before requesting a new code")
    if body.purpose == "reset_password" and not await db.scalar(select(User.id).where(User.phone == body.phone)):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No account with this phone number")

    # Only the newest code works
    await db.execute(
        update(PhoneOtp)
        .where(PhoneOtp.phone == body.phone, PhoneOtp.purpose == body.purpose, PhoneOtp.is_used.is_(False))
        .values(is_used=True)
    )
    code = generate_otp()
    db.add(
        PhoneOtp(
            phone=body.phone,
            purpose=body.purpose,
            code_hash=hash_otp(body.phone, code),
            expires_at=now + timedelta(minutes=settings.otp_ttl_minutes),
        )
    )
    if sms_enabled():
        try:
            await send_login_code(body.phone, code)
        except SmsError as e:
            # Nothing is saved, so the person can try again right away (no 60 s wait)
            await db.rollback()
            log.error("Login SMS to %s failed: %s", body.phone, e)
            raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Could not send the SMS, try again") from e
    await db.commit()

    if settings.otp_debug:
        log.info("SMS code for %s (%s): %s", body.phone, body.purpose, code)
    return OtpSentOut(expires_in=settings.otp_ttl_minutes * 60, debug_code=code if settings.otp_debug else None)


@router.post("/otp/verify", response_model=TokenOut)
async def verify_otp(body: OtpVerifyIn, db: DB, current: OptionalUser) -> TokenOut:
    """
    Logs in with an SMS code; creates the account if the number is new.
    Sent while logged in to an account without a phone (the app signs up with email first),
    it adds the number to that account instead of making a second one.
    """
    await _use_otp(db, body.phone, body.code, "login")
    user = await db.scalar(select(User).where(User.phone == body.phone))
    if current is not None and current.phone is None:
        if user is not None and user.id != current.id:
            raise HTTPException(status.HTTP_409_CONFLICT, "This phone number already belongs to another account")
        current.phone = body.phone
        return await _login(db, current)
    is_new = user is None
    if user is None:
        user = User(phone=body.phone)
        db.add(user)
        await db.flush()
    return await _login(db, user, is_new_user=is_new)


# ===== passwords =====
@router.post("/login", response_model=TokenOut)
async def login(body: PasswordLoginIn, db: DB) -> TokenOut:
    """Phone or email, plus password."""
    where = User.phone == body.phone if body.phone else User.email == body.email.lower()  # type: ignore[union-attr]
    user = await db.scalar(select(User).where(where))
    if user is None or not user.password or not verify_password(body.password, user.password):
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, f"Wrong {'phone number' if body.phone else 'email'} or password"
        )
    return await _login(db, user)


@router.post("/register", response_model=TokenOut, status_code=status.HTTP_201_CREATED)
async def register(body: EmailRegisterIn, db: DB) -> TokenOut:
    """Sign up with email + password (accounts made here are never admins)."""
    email = body.email.lower()
    if await db.scalar(select(User.id).where(User.email == email)):
        raise HTTPException(status.HTTP_409_CONFLICT, "This email is already registered")
    user = User(email=email, password=hash_password(body.password), full_name=body.full_name)
    db.add(user)
    await db.flush()
    return await _login(db, user, is_new_user=True)


@router.post("/password/reset", response_model=TokenOut)
async def reset_password(body: PasswordResetIn, db: DB) -> TokenOut:
    """Sets a new password with a reset_password SMS code, and logs in."""
    await _use_otp(db, body.phone, body.code, "reset_password")
    user = await db.scalar(select(User).where(User.phone == body.phone))
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No account with this phone number")
    user.password = hash_password(body.new_password)
    return await _login(db, user)


@router.post("/password/change", status_code=status.HTTP_204_NO_CONTENT)
async def change_password(body: PasswordChangeIn, user: CurrentUser, db: DB) -> Response:
    if user.password and not (body.old_password and verify_password(body.old_password, user.password)):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Wrong current password")
    user.password = hash_password(body.new_password)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ===== Google / Apple =====
@router.post("/social", response_model=TokenOut)
async def social_login(body: SocialLoginIn, db: DB) -> TokenOut:
    try:
        identity = verify_id_token(body.provider, body.id_token)
    except SocialAuthError as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, str(e)) from e

    account = await db.scalar(
        select(SocialAccount).where(SocialAccount.provider == body.provider, SocialAccount.uid == identity.uid)
    )
    if account:
        user = await db.get(User, account.user_id)
        assert user is not None
        if identity.email and account.email != identity.email:
            account.email = identity.email
        return await _login(db, user)

    # A verified email that matches an account signs into that account
    email = identity.email.lower() if identity.email else None
    user = await db.scalar(select(User).where(User.email == email)) if email else None
    is_new = user is None
    if user is None:
        user = User(full_name=body.full_name or identity.name, email=email)
        db.add(user)
        await db.flush()
    db.add(SocialAccount(user_id=user.id, provider=body.provider, uid=identity.uid, email=identity.email))
    return await _login(db, user, is_new_user=is_new)


# ===== Firebase Authentication (app: email/password) =====
FIREBASE = "firebase"


@router.post("/firebase", response_model=TokenOut)
async def firebase_login(body: FirebaseLoginIn, db: DB) -> TokenOut:
    """
    Trades a Firebase ID token for this API's tokens. The first time, it creates the account,
    or joins an existing account with the same email if Firebase has verified that email.
    """
    try:
        identity = await verify_firebase_token(body.id_token)
    except FirebaseAuthError as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, str(e)) from e

    account = await db.scalar(
        select(SocialAccount).where(SocialAccount.provider == FIREBASE, SocialAccount.uid == identity.uid)
    )
    if account:
        user = await db.get(User, account.user_id)
        assert user is not None
        return await _login(db, user)

    user = await db.scalar(select(User).where(User.email == identity.email)) if identity.email else None
    is_new = user is None
    if user is not None and not identity.email_verified:
        # Joining needs proof that this person owns the email, or anyone could take the account
        raise HTTPException(
            status.HTTP_409_CONFLICT, "This email already has an account: verify your email, then sign in again"
        )
    if user is None:
        user = User(email=identity.email, full_name=body.full_name or identity.name)
        db.add(user)
        await db.flush()
    db.add(SocialAccount(user_id=user.id, provider=FIREBASE, uid=identity.uid, email=identity.email))
    return await _login(db, user, is_new_user=is_new)


# ===== session =====
@router.post("/refresh", response_model=TokenOut)
async def refresh(body: RefreshIn, db: DB) -> TokenOut:
    user_id = decode_token(body.refresh_token, "refresh")
    user = await db.get(User, user_id) if user_id else None
    if user is None or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Session expired, log in again")
    return await _login(db, user)


@router.get("/me", response_model=ProfileOut)
async def me(user: CurrentUser) -> ProfileOut:
    return profile_out(user)
