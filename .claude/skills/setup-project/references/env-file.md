# .env — file chứa token Cloudflare (ở gốc dự án)

Đây là nơi **duy nhất** chứa thông tin nhạy cảm. Cả 4 skill đều đọc `./.env`. Token KHÔNG bao giờ nằm trong `site.config.json`.

## Vị trí & quyền

- Đặt ở gốc thư mục làm việc của dự án: `./.env`.
- Phải nằm trong `.gitignore` (setup-project tự thêm). Đặt quyền `chmod 600`.

## Nội dung

Đúng 2 biến (mỗi dòng `KEY=VALUE`, không có dấu cách quanh `=`):

```dotenv
# Cloudflare credentials — KHÔNG commit, KHÔNG chia sẻ.
CF_API_TOKEN=cf_xxx_token_gioi_han_quyen
CF_ACCOUNT_ID=0123456789abcdef0123456789abcdef
```

| Biến | Ý nghĩa | Lấy ở đâu |
|---|---|---|
| `CF_API_TOKEN` | API token giới hạn quyền (KHÔNG phải Global API Key). | Người dùng tự tạo — xem [`cloudflare-signup.md`](cloudflare-signup.md) + [`api-token-scopes.md`](api-token-scopes.md). |
| `CF_ACCOUNT_ID` | Cloudflare Account ID. | Workers & Pages → cột phải. |

## Agent ghi `.env` thế nào (sau khi người dùng đưa token)

1. Người dùng dán token + Account ID vào chat.
2. Agent ghi thẳng vào `.env` (heredoc trong SKILL.md), **không in lại token**, chỉ xác nhận 4 ký tự cuối.
3. Chạy `scripts/verify-cloudflare.sh` để chắc token sống và account đúng.

## File mẫu cho người dùng

Có thể đưa người dùng file `.env.example` (trong [`../assets/.env.example`](../assets/.env.example)) để họ thấy hình dạng. Họ chỉ cần thay 2 giá trị rồi đổi tên thành `.env` — nhưng thường agent ghi hộ luôn nên không bắt buộc.

## Cách các skill nạp `.env`

- Script bash: `set -a; . ./.env; set +a` rồi dùng `$CF_API_TOKEN`, `$CF_ACCOUNT_ID`. Với wrangler, export thêm `CLOUDFLARE_API_TOKEN`/`CLOUDFLARE_ACCOUNT_ID` từ 2 biến trên (các script deploy đã làm sẵn).
- Script Node (`sync-access.mjs`): tự đọc & parse `.env`, không cần source trước.

## Lưu ý

- Đổi token: chỉ cần sửa `CF_API_TOKEN` trong `.env`, không phải đụng gì khác.
- Lộ token: vào Cloudflare → My Profile → API Tokens → Roll/Delete token cũ, tạo token mới, cập nhật `.env`.
