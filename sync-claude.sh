#!/usr/bin/env bash
# sync-claude.sh — đồng bộ bản nguồn `new-claude/` sang bản chạy `.claude/`.
#
# Quy ước repo: SỬA Ở `new-claude/` TRƯỚC, duyệt xong chạy script này để
# copy sang `.claude/` (thư mục Claude Code thật sự dùng).
#
# Hướng đồng bộ: new-claude/  ──►  .claude/   (một chiều, .claude là bản đích)
#
# Dùng:
#   bash sync-claude.sh           # đồng bộ thật
#   bash sync-claude.sh --check   # chỉ xem sẽ thay đổi gì, KHÔNG ghi (dry-run)
#
# Lưu ý:
#   - Dùng rsync --delete: file đã xoá ở new-claude cũng bị xoá ở .claude
#     (để hai bên giống hệt nhau).
#   - KHÔNG đụng tới settings.local.json (config máy cá nhân, mỗi bên giữ riêng)
#     và .DS_Store.
set -euo pipefail

# Chạy ở gốc repo (nơi chứa cả new-claude/ và .claude/)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

SRC="new-claude/"
DEST=".claude/"

if [ ! -d "$SRC" ]; then echo "✗ Không thấy thư mục nguồn $SRC" >&2; exit 1; fi
mkdir -p "$DEST"

DRY=""
if [ "${1:-}" = "--check" ] || [ "${1:-}" = "-n" ]; then
  DRY="--dry-run"
  echo "== CHẾ ĐỘ XEM TRƯỚC (dry-run) — không ghi gì =="
fi

# -a: giữ nguyên cấu trúc/quyền; -i: in từng thay đổi; --delete: xoá file thừa ở đích
rsync -a -i --delete $DRY \
  --exclude 'settings.local.json' \
  --exclude '.DS_Store' \
  "$SRC" "$DEST"

echo ""
if [ -n "$DRY" ]; then
  echo "→ Đó là những gì SẼ thay đổi. Bỏ --check để áp dụng thật."
else
  echo "✓ Đã đồng bộ $SRC → $DEST"
  # Cảnh báo nếu còn khác nhau (ngoài file loại trừ)
  if diff -rq --exclude='settings.local.json' --exclude='.DS_Store' "$SRC" "$DEST" >/dev/null 2>&1; then
    echo "✓ Hai thư mục đã giống hệt nhau (trừ settings.local.json / .DS_Store)."
  else
    echo "⚠ Vẫn còn khác biệt — kiểm tra:"
    diff -rq --exclude='settings.local.json' --exclude='.DS_Store' "$SRC" "$DEST" || true
  fi
fi
