#!/usr/bin/env bash
# verify-cloudflare.sh — kiểm tra .env có token Cloudflare sống và account đúng.
#
# Chạy ở GỐC dự án (nơi có .env) SAU khi đã ghi token vào .env:
#   bash .codex/skills/setup-project/scripts/verify-cloudflare.sh
#
# Không in token ra màn hình (chỉ hiện 4 ký tự cuối). Trả về exit code != 0 nếu lỗi.
set -euo pipefail

if [ ! -f .env ]; then
  echo "✗ Không thấy .env ở thư mục hiện tại. Hãy ghi token vào .env trước." >&2
  exit 1
fi
set -a; . ./.env; set +a

: "${CF_API_TOKEN:?Thiếu CF_API_TOKEN trong .env}"
: "${CF_ACCOUNT_ID:?Thiếu CF_ACCOUNT_ID trong .env}"

TAIL="${CF_API_TOKEN: -4}"
echo "==> Dùng token …$TAIL, account $CF_ACCOUNT_ID"

# 1. Token còn sống?
echo "==> Kiểm tra token (tokens/verify)"
VERIFY="$(curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/user/tokens/verify")"
if echo "$VERIFY" | grep -q '"status":"active"'; then
  echo "    ✓ token active."
else
  echo "    ✗ token KHÔNG active. Phản hồi:" >&2
  echo "$VERIFY" >&2
  exit 1
fi

# 2. Token có truy cập được account này không? (gọi 1 endpoint account-scoped)
echo "==> Kiểm tra quyền trên account (liệt kê Pages projects)"
PAGES="$(curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/pages/projects")"
if echo "$PAGES" | grep -q '"success":true'; then
  echo "    ✓ token truy cập được account + có quyền Pages."
else
  echo "    ⚠ không gọi được Pages projects trên account này. Có thể token thiếu quyền"
  echo "      'Cloudflare Pages: Edit' hoặc Account ID sai. Phản hồi:" >&2
  echo "$PAGES" >&2
  exit 1
fi

echo ""
echo "✓ .env hợp lệ. Sẵn sàng chạy create-web."
