#!/usr/bin/env bash
# sync.sh — đồng bộ bản nguồn `new-claude/` sang các bản chạy cho từng agent.
#
# Quy ước repo: SỬA Ở `new-claude/` TRƯỚC, duyệt xong chạy script này để cập nhật
# CẢ HAI bản chạy cùng lúc. Thư mục đích chưa có sẽ được tạo mới rồi sync.
#
#   new-claude/  ──►  .claude/   (Claude Code) — giữ nguyên, dùng CLAUDE.md
#   new-claude/  ──►  .codex/    (Codex)       — đổi CLAUDE.md → AGENT.md,
#                                                và đường dẫn .claude → .codex trong nội dung
#
# Dùng:
#   bash sync.sh           # đồng bộ thật cả 2
#   bash sync.sh --check   # chỉ xem sẽ thay đổi gì, KHÔNG ghi (dry-run)
#
# Lưu ý:
#   - rsync --delete: file đã xoá ở new-claude cũng bị xoá ở bản đích (giống hệt nguồn).
#   - KHÔNG đụng settings.local.json (config máy cá nhân, mỗi bên giữ riêng) và .DS_Store.
#   - Bản .codex được dựng LẠI từ nguồn mỗi lần chạy (sync rồi mới đổi tên/đường dẫn),
#     nên luôn nhất quán dù chạy nhiều lần.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

SRC="new-claude/"
[ -d "$SRC" ] || { echo "✗ Không thấy thư mục nguồn $SRC" >&2; exit 1; }

DRY=""
if [ "${1:-}" = "--check" ] || [ "${1:-}" = "-n" ]; then
  DRY="--dry-run"
  echo "== CHẾ ĐỘ XEM TRƯỚC (dry-run) — không ghi gì =="
fi

RSYNC_OPTS=(-a -i --delete --exclude 'settings.local.json' --exclude '.DS_Store')

# ---------- 1) Claude: new-claude/ -> .claude/ (nguyên trạng) ----------
echo "==> [Claude] new-claude/ -> .claude/"
mkdir -p .claude
rsync "${RSYNC_OPTS[@]}" $DRY "$SRC" ".claude/"

# ---------- 2) Codex: new-claude/ -> .codex/ rồi biến đổi ----------
echo "==> [Codex]  new-claude/ -> .codex/"
mkdir -p .codex
rsync "${RSYNC_OPTS[@]}" $DRY "$SRC" ".codex/"

if [ -z "$DRY" ]; then
  # a) Đổi tên mọi CLAUDE.md -> AGENT.md trong .codex
  find .codex -type f -name 'CLAUDE.md' | while IFS= read -r f; do
    mv "$f" "$(dirname "$f")/AGENT.md"
  done
  # b) Viết lại tham chiếu trong nội dung: .claude -> .codex và CLAUDE.md -> AGENT.md
  #    (chỉ trong .codex; \.claude có escape nên KHÔNG đụng "new-claude")
  find .codex -type f \( -name '*.md' -o -name '*.sh' -o -name '*.mjs' -o -name '*.txt' -o -name '*.json' \) -print0 \
    | xargs -0 perl -pi -e 's/\.claude/.codex/g; s/CLAUDE\.md/AGENT.md/g'
fi

echo ""
if [ -n "$DRY" ]; then
  echo "→ Đó là những gì SẼ copy. Riêng .codex sau khi copy còn được đổi CLAUDE.md→AGENT.md"
  echo "  và .claude→.codex trong nội dung. Bỏ --check để áp dụng thật."
else
  echo "✓ Đã đồng bộ new-claude/ → .claude/ (Claude) và .codex/ (Codex)."
  echo "  - .claude: $(find .claude -type f | wc -l | tr -d ' ') file"
  echo "  - .codex : $(find .codex  -type f | wc -l | tr -d ' ') file (CLAUDE.md đã đổi thành AGENT.md)"
fi
