#!/usr/bin/env bash
# init-access-control.sh — tạo thư mục access-control/ ở GỐC dự án để người dùng
# tự khai báo "ai xem được trang nào", KHÔNG cần đụng vào thư mục skill.
#
# Chạy ở gốc dự án:
#   bash .claude/skills/access-control/scripts/init-access-control.sh
#
# Tạo (nếu chưa có):
#   access-control/access.csv   — file người dùng tự sửa (email -> pages)
#   access-control/README.txt   — hướng dẫn điền ngắn gọn
#
# Idempotent: nếu access.csv đã tồn tại thì KHÔNG ghi đè (giữ liệu người dùng).
set -euo pipefail

DIR="access-control"
CSV="$DIR/access.csv"
README="$DIR/README.txt"

mkdir -p "$DIR"

if [ -f "$CSV" ]; then
  echo "✓ Đã có $CSV — giữ nguyên, không ghi đè."
else
  cat > "$CSV" <<'EOF'
email,pages
usr1@gmail.com,page1;page2
usr2@gmail.com,page2
usr3@gmail.com,page1;page3
EOF
  echo "✓ Đã tạo mẫu $CSV — hãy sửa file này cho đúng người + trang của bạn."
fi

# README luôn ghi lại (chỉ là hướng dẫn, không phải liệu người dùng)
cat > "$README" <<'EOF'
THƯ MỤC PHÂN QUYỀN XEM TRANG
============================

Sửa file access.csv để quyết định AI xem được TRANG NÀO. Đây là nguồn chân lý:
chạy lại skill access-control sẽ đồng bộ Cloudflare đúng theo file này (ai bị xóa
khỏi file sẽ mất quyền).

Định dạng access.csv — đúng 2 cột, có dòng tiêu đề:

    email,pages
    an@gmail.com,page1;page2
    binh@gmail.com,page2

- Cột email : một địa chỉ email mỗi dòng.
- Cột pages : các slug trang mà email đó được xem, ngăn nhau bằng dấu ;
              Dùng đúng slug trang (vd: page1, gioi-thieu) — KHÔNG dùng URL,
              KHÔNG có dấu /. Các slug hợp lệ nằm trong site.config.json (mục "pages").

Mẹo: có thể mở/sửa bằng Excel hoặc Google Sheets rồi xuất lại .csv (UTF-8).
Sửa xong, nói với trợ lý: "cập nhật phân quyền" để áp dụng.
EOF

echo "✓ Đã ghi $README"
echo ""
echo "Bước tiếp: mở $CSV, điền email + trang, rồi nói 'cập nhật phân quyền'."
