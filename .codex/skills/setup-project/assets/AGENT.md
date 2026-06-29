# AGENT.md — Dự án web (Docusaurus + Cloudflare Pages)

Dự án này dựng bằng bộ 4 skill cho người dùng **non-tech**. File này nhắc agent các quy ước xuyên suốt cả 4 skill; chi tiết từng bước nằm trong `.codex/skills/<skill>/SKILL.md`.

## Người dùng là non-tech
- Họ mô tả nội dung bằng lời → **agent sinh Markdown**. KHÔNG bắt họ viết `.md`, KHÔNG bắt đụng API/CLI.
- Giải thích bằng ngôn ngữ thường, tránh thuật ngữ.

## Vòng đời (đúng thứ tự)
1. **setup-project** — Cloudflare token + Zero Trust, sinh `.env` + `site.config.json`.
2. **create-web** — scaffold Docusaurus, sinh nội dung từ mô tả, deploy lần đầu.
3. **update-content** — sửa/thêm nội dung, build lại, redeploy.
4. **access-control** — phân quyền xem trang theo CSV.

Luôn **đọc `site.config.json` trước** để biết đang ở bước nào, tránh hỏi lại.

## File dùng chung ở gốc dự án
| File | Vai trò |
|---|---|
| `.env` | Token Cloudflare (`CF_API_TOKEN`, `CF_ACCOUNT_ID`). Gitignore. Nơi DUY NHẤT chứa token. |
| `site.config.json` | Cấu hình + trạng thái (projectName, domain, pages, status). |
| `<projectName>/` | Source Docusaurus. |
| `access-control/access.csv` | Người dùng tự sửa: ai xem được trang nào. |

## Script (chạy ở gốc dự án)
- Deploy / redeploy: `bash .codex/skills/create-web/scripts/deploy.sh`
- Phân quyền: `node .codex/skills/access-control/scripts/sync-access.mjs [--dry-run|--prune]`
- Kiểm tra token: `bash .codex/skills/setup-project/scripts/verify-cloudflare.sh`

## Mặc định
Deploy direct-upload (không GitHub), login OTP (không Google OAuth), domain `.pages.dev` (free).

## Bảo mật
Token chỉ ở `.env`, không in ra màn hình/log (cần xác nhận thì chỉ hiện 4 ký tự cuối), không ghi vào `site.config.json`.
