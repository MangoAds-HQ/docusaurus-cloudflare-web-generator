---
name: setup-project
description: Bước đầu tiên trong quy trình dựng web cho người dùng không rành kỹ thuật (non-tech). Dùng skill này khi người dùng muốn "bắt đầu làm web", "tạo trang web mới", "setup project", "đăng ký Cloudflare", hoặc khi chưa có file site.config.json trong thư mục làm việc. Skill này kiểm tra công cụ cần thiết trên máy, hướng dẫn người dùng đăng ký Cloudflare + tạo API token có giới hạn quyền, bật Zero Trust, và sinh ra file site.config.json + file .env (chứa token) để các skill create-web, update-content, access-control dùng tiếp. LUÔN chạy skill này trước khi chạy ba skill kia.
metadata:
  author: MangoAds Co., Ltd.
  copyright: Copyright (c) 2024-2026 MangoAds Co., Ltd. All rights reserved.
license: Proprietary — All rights reserved. See LICENSE file for details.
---

# setup-project

Bước khởi tạo. Mục tiêu: kết thúc skill này, thư mục làm việc có một `site.config.json` hợp lệ + một file `.env` chứa token Cloudflare, và mọi prerequisite đã sẵn sàng để `create-web` chạy được ngay.

Người dùng là dân **non-tech**. Giải thích từng bước bằng ngôn ngữ thường, tránh thuật ngữ. Khi cần họ thao tác trên web Cloudflare, mô tả đúng nút bấm, đừng giả định họ biết "DNS", "token scope" là gì.

## Quy trình (chạy theo thứ tự)

### Bước 1 — Kiểm tra công cụ trên máy

Chạy kiểm tra, nếu thiếu thì hướng dẫn cài (xem [`references/toolchain.md`](references/toolchain.md)):

```bash
node -v    # cần >= 18
npm -v
git --version   # chỉ cần nếu chọn deploy qua GitHub; mặc định KHÔNG cần
```

Mặc định dự án này deploy bằng **direct upload (wrangler)**, KHÔNG cần GitHub — gọn hơn cho non-tech. Chỉ yêu cầu git nếu người dùng chủ động muốn dùng GitHub.

### Bước 2 — Đăng ký Cloudflare + lấy API token

Đây là phần người dùng phải tự làm trên trình duyệt. Đọc và đi theo [`references/cloudflare-signup.md`](references/cloudflare-signup.md) để hướng dẫn họ:
1. Tạo tài khoản Cloudflare (miễn phí).
2. Tạo **API token có giới hạn quyền** (KHÔNG dùng Global API Key — xem lý do trong file).
3. Copy Account ID.

Quyền chính xác cần gắn cho token: xem [`references/api-token-scopes.md`](references/api-token-scopes.md).

Khi người dùng đưa token, **ghi ngay vào file `.env` ở gốc dự án**, không in lại token ra màn hình, không ghi vào `site.config.json`. Cấu trúc `.env` + file mẫu: xem [`references/env-file.md`](references/env-file.md).

```bash
cat > .env <<EOF
# Cloudflare credentials — KHÔNG commit, KHÔNG chia sẻ.
CF_API_TOKEN=<token người dùng đưa>
CF_ACCOUNT_ID=<account id>
EOF
# luôn gitignore .env (kể cả khi chưa chắc dùng git)
grep -qxF '.env' .gitignore 2>/dev/null || echo '.env' >> .gitignore
chmod 600 .env
```

Kiểm tra token sống + account đúng bằng script có sẵn (không in token, chỉ hiện 4 ký tự cuối):
```bash
bash .claude/skills/setup-project/scripts/verify-cloudflare.sh
# kỳ vọng: "✓ .env hợp lệ. Sẵn sàng chạy create-web."
```

### Bước 3 — Bật Zero Trust (cần cho phân quyền sau này)

Access (phân quyền page) chỉ chạy khi tài khoản đã bật Zero Trust và đặt **team name** một lần. Đi theo [`references/zero-trust-onboarding.md`](references/zero-trust-onboarding.md). Nếu người dùng chưa định làm phân quyền ngay, vẫn nên bật luôn cho đỡ vướng về sau, nhưng có thể đánh dấu `zeroTrustEnabled: false` và nhắc lại khi chạy `access-control`.

### Bước 4 — Sinh site.config.json

Hỏi người dùng vài thứ tối thiểu (tên project, có dùng tên miền riêng không) rồi tạo file theo schema trong [`references/site-config-schema.md`](references/site-config-schema.md).

Lưu ý: `projectName` sẽ thành `<projectName>.pages.dev` và **không đổi được sau khi tạo** — chọn cẩn thận, chỉ chữ thường/số/gạch ngang.

### Bước 5 — Sinh CLAUDE.md ở gốc dự án

Tạo `CLAUDE.md` ở gốc dự án (nếu chưa có) để mỗi phiên Claude sau này tự có context về quy ước cả 4 skill (vòng đời, file dùng chung, script, bảo mật). Copy từ template:

```bash
[ -f CLAUDE.md ] || cp .claude/skills/setup-project/assets/CLAUDE.md ./CLAUDE.md
```

> `CLAUDE.md` chỉ auto-load khi nằm ở gốc thư mục nơi chạy Claude — vì vậy đặt ở gốc dự án, KHÔNG để trong `.claude/`.

## Kết thúc skill

Báo người dùng: đã xong khâu chuẩn bị, giờ có thể nói "tạo web cho tôi" để chạy `create-web`. Tóm tắt ngắn gọn: project tên gì, URL sẽ là gì, đã có token chưa, Zero Trust bật chưa.

## Lưu ý an toàn

- Không bao giờ in token đầy đủ ra màn hình hay log. Khi cần xác nhận, chỉ hiện 4 ký tự cuối.
- File `.env` phải nằm trong `.gitignore` (skill này tự thêm). Đây là nơi DUY NHẤT chứa token; ba skill kia đều đọc `.env`.
- Token chỉ nên có đúng quyền trong `api-token-scopes.md` — nếu người dùng lỡ tạo token quyền rộng hơn, khuyên họ thu hẹp lại.
