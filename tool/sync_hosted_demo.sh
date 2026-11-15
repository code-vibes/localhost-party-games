#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
flutter build web --release --base-href "/localhost-party-games/"
rm -rf hosted
cp -a build/web hosted
touch hosted/.nojekyll
echo "Synced hosted/ for GitHub Pages"
