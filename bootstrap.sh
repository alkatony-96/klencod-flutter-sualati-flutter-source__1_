#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:-"$ROOT/../sualati-app"}"
mkdir -p "$(dirname "$DEST")"
DEST="$(cd "$(dirname "$DEST")" && pwd)/$(basename "$DEST")"
if [[ -e "$DEST" ]]; then
  echo "المجلد موجود مسبقًا ولن أستبدله: $DEST" >&2
  exit 1
fi
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter غير مثبت أو غير موجود في PATH. ثبّت Flutter ثم أعد تشغيل السكربت." >&2
  exit 127
fi

WORK="$(mktemp -d "$(dirname "$DEST")/.sualati-build.XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT
PROJECT="$WORK/project"
flutter create --empty --project-name sualati --org com.sualati --platforms=android,ios "$PROJECT"
rm -rf "$PROJECT/lib" "$PROJECT/assets"
cp -R "$ROOT/lib" "$PROJECT/lib"
cp -R "$ROOT/assets" "$PROJECT/assets"
cp "$ROOT/pubspec.yaml" "$PROJECT/pubspec.yaml"
cp "$ROOT/README.md" "$PROJECT/README.md"
(
  cd "$PROJECT"
  flutter pub get
)
mv "$PROJECT" "$DEST"
echo "تم إنشاء مشروع Flutter هنا: $DEST"
