#!/usr/bin/env bash
# deploy.sh — build + deploy web Docusaurus lên Cloudflare Pages (direct upload).
#
# Dùng cho CẢ deploy lần đầu (create-web) lẫn redeploy (update-content):
# script tự tạo Pages project nếu chưa có, rồi deploy. Idempotent.
#
# Chạy ở GỐC dự án (nơi có site.config.json và .env):
#   bash .codex/skills/create-web/scripts/deploy.sh
#
# Tùy chọn:
#   --no-build      bỏ qua bước npm run build (dùng khi đã build sẵn)
#   --project NAME  ép tên project (mặc định đọc từ site.config.json)
set -euo pipefail

NO_BUILD=0
PROJECT_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --no-build) NO_BUILD=1; shift ;;
    --project) PROJECT_OVERRIDE="${2:-}"; shift 2 ;;
    *) echo "Tham số không hiểu: $1" >&2; exit 2 ;;
  esac
done

# --- Nạp credentials từ .env ở gốc dự án ---
if [ ! -f .env ]; then
  echo "✗ Không thấy .env ở thư mục hiện tại. Hãy chạy setup-project trước." >&2
  exit 1
fi
set -a; . ./.env; set +a

: "${CF_API_TOKEN:?Thiếu CF_API_TOKEN trong .env}"
: "${CF_ACCOUNT_ID:?Thiếu CF_ACCOUNT_ID trong .env}"
# wrangler đọc các biến CLOUDFLARE_*:
export CLOUDFLARE_API_TOKEN="$CF_API_TOKEN"
export CLOUDFLARE_ACCOUNT_ID="$CF_ACCOUNT_ID"

# --- Lấy projectName ---
if [ -n "$PROJECT_OVERRIDE" ]; then
  PROJECT="$PROJECT_OVERRIDE"
elif [ -f site.config.json ]; then
  PROJECT="$(node -e "process.stdout.write(require('./site.config.json').projectName||'')")"
else
  echo "✗ Không thấy site.config.json và không có --project. Dừng." >&2
  exit 1
fi
if [ -z "$PROJECT" ]; then
  echo "✗ Không xác định được projectName." >&2
  exit 1
fi
if [ ! -d "$PROJECT" ]; then
  echo "✗ Không thấy thư mục project '$PROJECT'. Đã chạy create-web (scaffold) chưa?" >&2
  exit 1
fi

# --- Build ---
if [ "$NO_BUILD" -eq 0 ]; then
  echo "==> Build '$PROJECT' (npm run build)"
  ( cd "$PROJECT" && npm run build )
fi
if [ ! -d "$PROJECT/build" ]; then
  echo "✗ Không thấy '$PROJECT/build'. Build thất bại hoặc đã chạy --no-build mà chưa build." >&2
  exit 1
fi

# --- Tạo Pages project nếu chưa có (idempotent) ---
echo "==> Đảm bảo Pages project '$PROJECT' tồn tại"
if npx --yes wrangler pages project create "$PROJECT" --production-branch main 2>/dev/null; then
  echo "    đã tạo project mới."
else
  echo "    project đã tồn tại — bỏ qua bước tạo."
fi

# --- Deploy ---
echo "==> Deploy '$PROJECT/build' lên production (branch main)"
npx --yes wrangler pages deploy "$PROJECT/build" --project-name "$PROJECT" --branch main

echo ""
echo "✓ Deploy xong. URL production: https://$PROJECT.pages.dev"
echo "  (Lần đầu có thể mất 1-2 phút để lan truyền.)"
