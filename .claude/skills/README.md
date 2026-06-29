# Bộ skill dựng web cho người dùng non-tech

4 skill độc lập nhưng nối nhau qua một file dùng chung `site.config.json` (token để riêng ở `.cloudflare-secret`). Thứ tự vòng đời:

```
1. setup-project   → đăng ký Cloudflare, lấy API token (giới hạn quyền),
                      bật Zero Trust, sinh site.config.json + .cloudflare-secret
2. create-web      → scaffold Docusaurus, sinh Markdown từ mô tả người dùng,
                      deploy lần đầu lên <project>.pages.dev
3. update-content  → sửa/thêm nội dung, build lại, redeploy
4. access-control  → đọc CSV (email→pages), provision Cloudflare Access
                      theo path, login OTP, đồng bộ theo CSV
```

## Nguyên tắc chung

- Mỗi skill **đọc `site.config.json` trước** để biết đang ở đâu, tránh hỏi lại.
- Người dùng non-tech: họ mô tả/đưa liệu thô, agent lo phần kỹ thuật. Không bắt họ viết Markdown hay đụng API.
- Mặc định: deploy direct-upload (không GitHub), login OTP (không Google OAuth), domain `.pages.dev` free.

## Phần cần agent dựng script sau

Các file đánh dấu 🔧 trong `references/` là hướng dẫn + curl mẫu cho phần gọi Cloudflare API (Pages deploy direct-upload thuần API, Access provisioning). Hiện luồng chính dùng `wrangler` + curl là đủ; chủ dự án có thể script hóa các phần 🔧 theo nhu cầu:
- `create-web/references/deploy-first.md` — direct-upload API
- `update-content/references/build-and-deploy.md` — redeploy API
- `access-control/references/cloudflare-access-api.md` — Access app/policy + sync

## Bảo mật

- Token luôn ở `.cloudflare-secret` (gitignore), không in ra, không vào config.
- Token chỉ mang đúng quyền tối thiểu (xem `setup-project/references/api-token-scopes.md`).
