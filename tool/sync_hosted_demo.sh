#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
flutter build web --release --base-href "/localhost-party-games/"
mkdir -p docs/ci
CI_YML=docs/ci/github-actions-build.yml
[ -f docs/ci/github-actions-build.yml ] || true
find docs -maxdepth 1 -type f \( -name 'index.html' -o -name 'main.dart.js' -o -name 'flutter.js' -o -name 'flutter_bootstrap.js' -o -name 'flutter_service_worker.js' -o -name 'manifest.json' -o -name 'version.json' -o -name 'favicon.png' \) -delete
rm -rf docs/assets docs/canvaskit docs/icons
cp -a build/web/* docs/
touch docs/.nojekyll
echo "Synced Flutter web build into docs/ for GitHub Pages"
