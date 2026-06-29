---
name: update-content
description: Cập nhật nội dung cho website Docusaurus đã tạo, rồi build và đẩy bản mới lên Cloudflare Pages. Dùng skill này khi người dùng non-tech muốn "sửa nội dung", "thêm trang", "cập nhật web", "đăng bài mới", "đổi chữ trên trang X", hoặc sau khi web đã được tạo bằng create-web. Skill này nhận mô tả thay đổi từ người dùng (không cần họ viết Markdown), sửa file tương ứng, build lại và redeploy. LUÔN đọc site.config.json trước để biết project nào, các trang hiện có; nếu web chưa được tạo thì hướng người dùng chạy create-web.
metadata:
  author: MangoAds Co., Ltd.
  copyright: Copyright (c) 2024-2026 MangoAds Co., Ltd. All rights reserved.
license: Proprietary — All rights reserved. See LICENSE file for details.
---

# update-content

Mục tiêu: người dùng mô tả thay đổi → agent sửa file → build → đẩy bản mới lên web. Người dùng **non-tech**, không tự đụng Markdown.

## Trước khi bắt đầu

1. Đọc `site.config.json`. Không có, hoặc `status.firstDeploy != true` → web chưa sẵn sàng, hướng người dùng chạy `create-web` trước.
2. Lấy `projectName`, `contentDir`, mảng `pages` để biết đang có những trang nào.

## Quy trình

### Bước 1 — Hiểu người dùng muốn đổi gì

Các tình huống thường gặp:
- **Sửa nội dung trang có sẵn**: "đổi đoạn giới thiệu thành...", "thêm mục ABC vào trang X".
- **Thêm trang mới**: tạo `<contentDir>/<slug>.md` mới + cập nhật `pages` trong config + sidebar.
- **Xóa trang**: xóa file + gỡ khỏi `pages` + sidebar. Nhắc người dùng: nếu trang đó đang có Access policy, cần chạy `access-control` để dọn.
- **Đổi thông tin chung**: tên site, tagline, logo → sửa `docusaurus.config.js`.

Người dùng đưa mô tả/text thô, agent chuyển thành Markdown. Tham khảo cách sinh Markdown trong skill `create-web` (`references/content-input-guide.md`) — cùng quy ước frontmatter & slug.

### Bước 2 — Sửa file

- Áp thay đổi vào đúng file `.md` hoặc config.
- Nếu thêm/xóa trang → cập nhật mảng `pages` trong `site.config.json` cho khớp.
- Giữ `slug` ổn định nếu trang đã tồn tại (vì Access policy gắn theo path). Nếu buộc đổi slug, ghi chú để xử lý Access tương ứng.

### Bước 3 — Build + redeploy

Đi theo [`references/build-and-deploy.md`](references/build-and-deploy.md):

```bash
cd <projectName>
npm run build
source ../.cloudflare-secret
export CLOUDFLARE_API_TOKEN=$CF_API_TOKEN
export CLOUDFLARE_ACCOUNT_ID=$CF_ACCOUNT_ID
npx wrangler pages deploy build --project-name <projectName> --branch main
```

(Project đã tồn tại từ `create-web` nên không tạo lại, chỉ deploy.)

### Bước 4 — Xác nhận

Cập nhật `updatedAt` trong config. Báo người dùng đã cập nhật + URL để xem. Nhắc bản mới có thể mất chút thời gian lan truyền.

## Lưu ý

- Mỗi lần deploy tính 1 build. Bản Free Cloudflare Pages cho 500 build/tháng — thừa cho nhu cầu thường, nhưng đừng deploy lặp vô ích.
- Nếu thêm trang mới mà người dùng muốn giới hạn người xem ngay → sau khi deploy, gợi ý chạy `access-control` để gán quyền cho path mới.
- Build fail thường do frontmatter sai hoặc link nội bộ gãy — sửa rồi deploy lại, đừng đẩy bản lỗi.
