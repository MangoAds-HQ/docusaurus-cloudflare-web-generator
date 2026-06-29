#!/usr/bin/env bash
# scaffold.sh — tạo khung Docusaurus classic.
# Phần này KHÔNG đụng tới Cloudflare, nên chạy được luôn.
# Dùng: bash scaffold.sh <projectName>
set -euo pipefail

PROJECT_NAME="${1:-}"
if [ -z "$PROJECT_NAME" ]; then
  echo "Thiếu tên project. Dùng: bash scaffold.sh <projectName>" >&2
  exit 1
fi

if [ -d "$PROJECT_NAME" ]; then
  echo "Thư mục '$PROJECT_NAME' đã tồn tại — dừng để tránh ghi đè." >&2
  exit 1
fi

echo "==> Tạo Docusaurus classic project: $PROJECT_NAME"
npx --yes create-docusaurus@latest "$PROJECT_NAME" classic --typescript

echo "==> Cài dependencies"
cd "$PROJECT_NAME"
npm install

echo ""
echo "==> Xong. Khung đã tạo trong ./$PROJECT_NAME"
echo "    Bước tiếp theo (agent làm):"
echo "    - Sửa docusaurus.config.js (url, baseUrl=/, title, tagline)"
echo "    - Sinh các file docs/<slug>.md từ mô tả người dùng"
echo "    - npm run build để kiểm tra"
echo "    - Deploy theo references/deploy-first.md"
