---
name: create-web
description: Tạo một website Docusaurus mới theo yêu cầu của người dùng non-tech, rồi deploy lần đầu lên Cloudflare Pages để họ thấy web sống ngay. Dùng skill này khi người dùng nói "tạo web cho tôi", "làm website", "dựng trang Docusaurus", hoặc sau khi đã chạy setup-project xong. Skill này scaffold Docusaurus, hỏi người dùng về nội dung/cấu trúc trang rồi tự sinh các file Markdown tương ứng (người dùng chỉ cần mô tả, KHÔNG cần tự viết Markdown), cập nhật site.config.json, và deploy bản đầu tiên. LUÔN đọc site.config.json trước; nếu chưa có thì hướng người dùng chạy setup-project.
metadata:
  author: MangoAds Co., Ltd.
  copyright: Copyright (c) 2024-2026 MangoAds Co., Ltd. All rights reserved.
license: Proprietary — All rights reserved. See LICENSE file for details.
---

# create-web

Mục tiêu: từ mô tả của người dùng → một web Docusaurus chạy được, đã deploy lên `<project>.pages.dev`, và người dùng nhìn thấy nó online.

Người dùng **non-tech**: họ mô tả nội dung bằng lời, **agent sinh Markdown**. Đừng bắt họ tự viết file `.md` hay hiểu cú pháp.

## Trước khi bắt đầu

1. Đọc `site.config.json`. Nếu không có → bảo người dùng chạy `setup-project` trước, dừng lại.
2. Kiểm tra `status.toolchainReady` và `status.tokenCreated`. Thiếu thì quay lại setup-project.

## Quy trình

### Bước 1 — Scaffold Docusaurus

Chạy script tạo khung (xem [`scripts/scaffold.sh`](scripts/scaffold.sh)):

```bash
bash scripts/scaffold.sh <projectName>
```

Nó tạo project Docusaurus classic trong thư mục `<projectName>/`. Sau đó sửa `docusaurus.config.js`: đặt `url` = domain trong config, `baseUrl` = `/`, tên site, tagline theo ý người dùng.

### Bước 2 — Thu thập nội dung (hỏi mô tả, không bắt viết Markdown)

Hỏi người dùng họ muốn web có những trang nào và nội dung mỗi trang. Hỏi gọn, từng nhóm một. Cách lấy liệu hiệu quả với non-tech: xem [`references/content-input-guide.md`](references/content-input-guide.md).

Nguyên tắc: người dùng đưa **text thô / gạch đầu dòng / mô tả**, agent chuyển thành Markdown đúng chuẩn Docusaurus (frontmatter, heading, link). Mỗi trang → một file trong thư mục `contentDir` (mặc định `docs/`).

### Bước 3 — Sinh file Markdown + cập nhật cấu trúc

- Với mỗi trang, tạo `docs/<slug>.md` với frontmatter tối thiểu:
  ```markdown
  ---
  id: page1
  title: Trang 1
  slug: /page1
  ---
  ```
- `slug` quyết định URL (`/page1`) — đây chính là path mà `access-control` sẽ khóa sau này, nên đặt nhất quán và lưu lại.
- Cập nhật sidebar nếu cần (`sidebars.js`).
- Ghi từng trang vào mảng `pages` trong `site.config.json` (slug, path, title).

### Bước 4 — Build thử local

```bash
cd <projectName>
npm run build
```

Build lỗi thì sửa trước khi deploy (thường do frontmatter sai hoặc link gãy). (Bước build này không bắt buộc tách riêng — script deploy ở bước 5 tự build; nhưng build thử trước giúp bắt lỗi sớm.)

### Bước 5 — Deploy lần đầu lên Cloudflare Pages

Chạy script deploy ở **gốc dự án** (nó nạp `.env`, tự tạo Pages project nếu chưa có, build rồi deploy):

```bash
bash .claude/skills/create-web/scripts/deploy.sh
```

Chi tiết / xử lý lỗi / phương án thủ công: [`references/deploy-first.md`](references/deploy-first.md). Sau khi deploy:
- Set `status.webCreated = true`, `status.firstDeploy = true` trong `site.config.json`.
- Đưa người dùng URL `<project>.pages.dev` và bảo họ mở thử.

## Kết thúc skill

Báo người dùng web đã online + URL. Nhắc bước tiếp theo: muốn sửa/thêm nội dung thì dùng `update-content`; muốn giới hạn ai xem trang nào thì dùng `access-control`.

## Lưu ý

- `slug` của các trang là "hợp đồng" với skill `access-control`. Giữ chúng ổn định; nếu đổi slug sau này, phải cập nhật cả Access app.
- Mặc định deploy direct-upload (không GitHub). Nếu người dùng muốn GitHub thì xem ghi chú trong `deploy-first.md`.
