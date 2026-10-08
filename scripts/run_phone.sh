#!/usr/bin/env bash
# Runs the app on the phone connected by USB, with the phone's localhost:8000 forwarded to this laptop's
# backend (the forwarding resets whenever the phone is unplugged or restarted).
set -e
ADB="${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools/adb"
"$ADB" reverse tcp:8000 tcp:8000
echo "Phone localhost:8000 -> laptop backend"
cd "$(dirname "$0")/.."
exec flutter run "$@"
