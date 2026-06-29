# Bộ skill dựng web cho người dùng non-tech

4 skill độc lập nhưng nối nhau qua một file dùng chung `site.config.json` (token để riêng ở `.env`). Thứ tự vòng đời:

```
1. setup-project   → đăng ký Cloudflare, lấy API token (giới hạn quyền),
                      bật Zero Trust, sinh site.config.json + .env
2. create-web      → scaffold Docusaurus, sinh Markdown từ mô tả người dùng,
                      deploy lần đầu lên <project>.pages.dev
3. update-content  → sửa/thêm nội dung, build lại, redeploy
4. access-control  → đọc CSV (email→pages), provision Cloudflare Access
                      theo path, login OTP, đồng bộ theo CSV
```

## File ở gốc dự án (người dùng/agent tạo khi chạy skill)

| File / thư mục | Ai tạo | Vai trò |
|---|---|---|
| `.env` | setup-project | Token Cloudflare (`CF_API_TOKEN`, `CF_ACCOUNT_ID`). Gitignore. Mọi skill đọc file này. |
| `site.config.json` | setup-project | Cấu hình + trạng thái dùng chung (projectName, domain, pages, status…). |
| `AGENT.md` | setup-project | Context cho agent (vòng đời + file dùng chung + bảo mật). Đặt ở gốc project để auto-load; template ở `setup-project/assets/AGENT.md`. |
| `<projectName>/` | create-web | Source Docusaurus. |
| `access-control/access.csv` | access-control | Người dùng tự sửa: ai xem được trang nào. |

## Script gọi Cloudflare (agent chạy thẳng)

Phần connect Cloudflare đã được script hóa sẵn — không cần dựng tay nữa:

- `setup-project/scripts/verify-cloudflare.sh` — kiểm tra `.env` (token sống + account đúng).
- `create-web/scripts/deploy.sh` & `update-content/scripts/deploy.sh` — build + tạo project (nếu cần) + deploy Pages (idempotent; dùng cho cả deploy đầu lẫn redeploy).
- `access-control/scripts/init-access-control.sh` — tạo thư mục `access-control/` ở gốc dự án + file CSV mẫu cho người dùng sửa.
- `access-control/scripts/sync-access.mjs` — đồng bộ Cloudflare Access theo `access-control/access.csv` (OTP, idempotent, sync; có `--dry-run` và `--prune`).

Các file `references/` đi kèm giải thích cơ chế + endpoint để agent hiểu/sửa script khi API đổi.

## Nguyên tắc chung

- Mỗi skill **đọc `site.config.json` trước** để biết đang ở đâu, tránh hỏi lại.
- Người dùng non-tech: họ mô tả/đưa liệu thô, agent lo phần kỹ thuật. Không bắt họ viết Markdown hay đụng API. CSV phân quyền để ở gốc dự án (`access-control/`) để họ sửa, KHÔNG nằm trong thư mục skill.
- Mặc định: deploy direct-upload (không GitHub), login OTP (không Google OAuth), domain `.pages.dev` free.

## Bảo mật

- Token luôn ở `.env` (gitignore), không in ra, không vào config. Cấu trúc: `setup-project/references/env-file.md`.
- Token chỉ mang đúng quyền tối thiểu (xem `setup-project/references/api-token-scopes.md`).
