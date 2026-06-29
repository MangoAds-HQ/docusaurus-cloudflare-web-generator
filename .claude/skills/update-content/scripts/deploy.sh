#!/usr/bin/env bash
# deploy.sh — build + deploy web Docusaurus lên Cloudflare Pages (direct upload).
#
# Dùng cho CẢ deploy lần đầu (create-web) lẫn redeploy (update-content):
# script tự tạo Pages project nếu chưa có, rồi deploy. Idempotent.
#
# Chạy ở GỐC dự án (nơi có site.config.json và .env):
#   bash .claude/skills/create-web/scripts/deploy.sh
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

# --- Nạp credentials ---
# Hỗ trợ 2 cách xác thực với Cloudflare:
#   1) Token trong .env (CF_API_TOKEN + CF_ACCOUNT_ID) — phù hợp khi giao khách / CI,
#      và là cách DUY NHẤT mà access-control (REST API) dùng được.
#   2) Đăng nhập wrangler (npx wrangler login) — không cần token, gọn cho non-tech.
# Có .env thì nạp; không có cũng không sao nếu đã wrangler login.
if [ -f .env ]; then
  set -a; . ./.env; set +a
fi

if [ -n "${CF_API_TOKEN:-}" ]; then
  # Cách 1: dùng token từ .env (wrangler đọc biến CLOUDFLARE_*)
  export CLOUDFLARE_API_TOKEN="$CF_API_TOKEN"
  [ -n "${CF_ACCOUNT_ID:-}" ] && export CLOUDFLARE_ACCOUNT_ID="$CF_ACCOUNT_ID"
else
  # Cách 2: dựa vào phiên 'wrangler login' đã lưu
  if ! npx --yes wrangler whoami >/dev/null 2>&1; then
    echo "✗ Chưa có credential Cloudflare. Chạy 'npx wrangler login' hoặc tạo .env (CF_API_TOKEN)." >&2
    echo "  Xem skill setup-project để biết chi tiết." >&2
    exit 1
  fi
  # Nếu .env có sẵn account id thì truyền vào cho chắc (tài khoản có nhiều account):
  [ -n "${CF_ACCOUNT_ID:-}" ] && export CLOUDFLARE_ACCOUNT_ID="$CF_ACCOUNT_ID"
fi

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
