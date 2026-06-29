# CLAUDE.md — Repo phát triển bộ skill dựng web

Đây là **repo phát triển** bộ 4 skill (không phải project web của khách). Tổng quan + vòng đời chi tiết: [skills/README.md](skills/README.md).

## Quy ước repo
- Source skill nằm ở `new-claude/skills/`; `.claude/skills/` là bản đang chạy. **Sửa ở `new-claude/` trước**, người dùng duyệt rồi mới copy sang `.claude/`.
- Khi sửa skill, giữ hai cây đồng bộ sau khi duyệt.

## Bộ skill (đúng thứ tự vòng đời)
1. **setup-project** — Cloudflare token + Zero Trust → sinh `.env` + `site.config.json` (+ `CLAUDE.md` cho project khách).
2. **create-web** — scaffold Docusaurus, sinh nội dung, deploy lần đầu.
3. **update-content** — sửa nội dung, build lại, redeploy.
4. **access-control** — phân quyền xem trang theo CSV.

## Nguyên tắc thiết kế skill (giữ nhất quán khi sửa)
- Người dùng **non-tech**: họ mô tả → agent sinh Markdown / lo phần API. Không bắt họ viết `.md` hay đụng CLI.
- Mỗi skill **đọc `site.config.json` trước**; cập nhật cờ `status.*` khi xong một bước.
- File dùng chung ở gốc **project khách**: `.env` (token, gitignore, nơi DUY NHẤT chứa token), `site.config.json`, `access-control/access.csv`, `<projectName>/`.
- Script gọi Cloudflare: `*/scripts/deploy.sh`, `access-control/scripts/sync-access.mjs`, `setup-project/scripts/verify-cloudflare.sh`. Reference `references/*.md` giải thích cơ chế để đối chiếu khi API đổi.
- Mặc định: direct-upload (không GitHub), login OTP (không Google), domain `.pages.dev`.

## Bảo mật
Token chỉ ở `.env`, không in ra log (cần thì chỉ 4 ký tự cuối), không vào `site.config.json`.

> Lưu ý: file này chỉ auto-load khi ở gốc thư mục nơi chạy Claude. Khi finalize, nếu muốn nó auto-load lúc dev, đặt một bản ở gốc project (vd `./CLAUDE.md`), không phải trong `.claude/`.
