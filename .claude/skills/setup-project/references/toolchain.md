# Kiểm tra & cài công cụ

Người dùng non-tech thường chưa có sẵn Node.js. Thiếu nó thì mọi bước sau fail. Kiểm tra trước, cài nếu thiếu.

## Cần gì

| Công cụ | Vì sao | Bắt buộc? |
|---|---|---|
| Node.js >= 18 | Docusaurus + wrangler chạy trên Node | Có |
| npm | Đi kèm Node | Có |
| wrangler | CLI deploy lên Cloudflare Pages | Có (cài qua npm) |
| git | Chỉ cần nếu chọn deploy qua GitHub repo | Không (mặc định bỏ) |

## Kiểm tra

```bash
node -v
npm -v
npx wrangler --version 2>/dev/null || echo "chưa có wrangler"
```

## Cài Node nếu thiếu

Đừng bắt người dùng tự build. Hướng dẫn theo hệ điều hành:

- **macOS**: cài qua Homebrew `brew install node`, hoặc tải installer tại https://nodejs.org (bản LTS).
- **Windows**: tải installer LTS tại https://nodejs.org, next-next-finish.
- **Linux**: khuyên dùng nvm:
  ```bash
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  # mở terminal mới rồi:
  nvm install --lts
  ```

Với người dùng thật sự không quen terminal, ưu tiên hướng dẫn tải installer .pkg/.exe từ nodejs.org — ít sai nhất.

## Cài wrangler

Sau khi có Node:
```bash
npm install -g wrangler
```

Hoặc dùng `npx wrangler ...` từng lần (không cần cài global). Skill nên dùng `npx wrangler` để khỏi phụ thuộc cài global.

## Đăng nhập wrangler

Dự án này dùng API token (không dùng `wrangler login` tương tác). Set biến môi trường trước mỗi lệnh wrangler:

```bash
source .cloudflare-secret
export CLOUDFLARE_API_TOKEN=$CF_API_TOKEN
export CLOUDFLARE_ACCOUNT_ID=$CF_ACCOUNT_ID
```

> Lưu ý: wrangler đọc biến tên `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID`, khác tên trong file secret — nhớ map đúng như trên.
