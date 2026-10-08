# UzSL API

FastAPI + PostgreSQL backend for the SignLang mobile app and the admin dashboard (`uzsl_dashboard`).
The database follows the diagram exported to `schema.sql` (see the notes at the top of `app/models.py`).

## Run locally

```bash
docker compose up -d                 # PostgreSQL on :5432 (user/password/db: uzsl)
# or, without Docker: PostgreSQL from Python, data in .pgdata (run again after a restart);
# put the DATABASE_URL it prints in .env
uv run --with pgserver python scripts/local_db.py
cp .env.example .env                 # then set JWT_SECRET
uv sync
uv run alembic upgrade head          # create the tables
uv run python -m app.seed            # courses, lessons, categories, sample signs, achievements
uv run python -m app.cli create-admin --phone 901234567 --email you@example.com --password 'at-least-8-chars' --superuser
uv run fastapi dev app/main.py       # http://localhost:8000/docs
```

After changing `app/models.py`: `uv run alembic revision --autogenerate -m "what changed"` and `uv run alembic upgrade head`.

## Routes

JSON is camelCase. Send `Authorization: Bearer <accessToken>`. Full list with examples: `/docs`.

| Prefix | Who | What |
|---|---|---|
| `/api/v1/auth` | everyone | SMS code login/sign-up, phone or email + password, email sign-up, password reset (SMS), Google/Apple, refresh, `/me` |
| `/api/v1/app` | mobile app | profile, notification settings, devices, stats, activity, achievements, notifications; dictionary (categories, signs, saved, recent, offline packages); courses → lessons → attempts; dataset recordings; translator and quick phrases; uploads |
| `/api/v1/admin` | `is_staff` | stats, users, broadcast notifications, media upload; categories, signs, offline packages; courses, lessons, exercises, achievements, reports; dataset topics/words/recordings review; quick phrases |

### Lesson flow (app)

1. `GET /app/lessons/{id}`: signs and exercises, without the correct answers
2. `POST /app/lessons/{id}/attempts`: start
3. `POST /app/attempts/{id}/answers`: one per exercise, checked on the server
   (`{"optionId"}` for chooseText/chooseImage, `{"pairs": [[a, b], ...]}` for matching, `{"optionIds": [...]}` for order)
4. `POST /app/attempts/{id}/finish`: accuracy, XP, level, streak, learned signs, unlocked achievements

A lesson is completed at `LESSON_PASS_ACCURACY` (50%). Repeating a lesson only earns XP for a better score.

## Notes

- **SMS:** login codes are sent through Eskiz.uz when `SMS_PROVIDER=eskiz` (see "SMS login codes (Eskiz.uz)").
  With `OTP_DEBUG=true` (local development) the code is also logged and returned as `debugCode`.
- **Google/Apple:** set `GOOGLE_CLIENT_IDS` / `APPLE_CLIENT_IDS`; until then `/auth/social` answers 401.
- **Push notifications (FCM):** notifications from the dashboard and unlocked achievements are pushed to the
  learners' phones once `FCM_CREDENTIALS_FILE` points to a Firebase service account key (save it as
  `backend/firebase-key.json`, which git ignores). Phones register with `POST /app/devices` after login;
  tokens Firebase reports as gone are turned off. Without the key, notifications are in-app only.
- **Translator:** text becomes dictionary signs (phrases and words), unknown words are fingerspelled with letter signs.
  Video/audio messages are stored but not recognized yet.
- **Email:** `users.email` is an extra column (not in the diagram). Emails aren't verified yet and passwords
  can only be reset by SMS, so an email-only account that forgets its password needs an admin.
- **Admins:** signing up never makes an admin; use `python -m app.cli create-admin` / `make-admin` / `revoke-admin`.
  A superuser can also grant or remove admin rights in the dashboard.

## Deploy (public server)

Any Linux server (VPS) with Docker. Caddy gets the HTTPS certificate automatically.

1. Point a domain to the server: DNS **A record** `api.your-domain` → server IP. Open ports 80 and 443.
2. On the server:
   ```bash
   git clone <this repo> && cd signlang/backend/deploy
   cp .env.example .env        # set API_DOMAIN, POSTGRES_PASSWORD, JWT_SECRET (long random values)
   # copy the Firebase key here as deploy/firebase-key.json (secret)
   docker compose up -d --build
   ```
   Migrations and the starter textbooks run on every start. Check: `https://api.your-domain/health`.
3. First admin: `docker compose exec api python -m app.cli create-admin --email you@example.com --password '...' --superuser`
4. App: set `productionServer` in `lib/api/uzsl_api.dart` to `https://api.your-domain`, then `flutter build apk --release`.
5. Dashboard: build with `VITE_API_URL=https://api.your-domain`, and add its address to `CORS_ORIGINS` in `.env`.

Update to a new version: `git pull && docker compose up -d --build`.
Backups: `docker compose exec db pg_dump -U uzsl uzsl > backup.sql` (the `media` volume holds uploaded files).

### SMS login codes (Eskiz.uz)

Set `SMS_PROVIDER=eskiz`, `ESKIZ_EMAIL`, `ESKIZ_PASSWORD` (your my.eskiz.uz login) and `SMS_OTP_TEMPLATE`.
Eskiz only delivers texts approved as **templates** in your Eskiz account: submit exactly the text of
`SMS_OTP_TEMPLATE` with the code as a number (e.g. "UzSL: tasdiqlash kodi 123456") and wait for approval.
If sending fails (text not approved, no balance), the app gets "Could not send the SMS" and the error
is in the server log. Without an SMS provider and with `OTP_DEBUG=false`, phone login answers
"SMS login is not available yet"; email login (Firebase) still works.
