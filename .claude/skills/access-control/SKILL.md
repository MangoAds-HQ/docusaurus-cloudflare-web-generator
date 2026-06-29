---
name: access-control
description: Phân quyền xem trang trên website Cloudflare Pages — đọc danh sách email từ file CSV và cấu hình Cloudflare Access để chỉ những email được phép mới xem được từng trang tương ứng. Dùng skill này khi người dùng non-tech muốn "giới hạn người xem", "phân quyền trang", "chỉ cho một số người xem trang X", "ai đăng nhập mới xem được", "cập nhật danh sách truy cập", hoặc đưa một file CSV chứa email + trang. Skill đọc CSV (schema cố định email→pages), tạo/cập nhật Access application theo path + policy bằng email, mặc định đăng nhập bằng OTP (mã gửi qua email), và đồng bộ theo CSV (ai không còn trong CSV thì gỡ quyền). LUÔN đọc site.config.json trước; nếu Zero Trust chưa bật hoặc web chưa deploy thì hướng người dùng làm bước đó trước.
metadata:
  author: MangoAds Co., Ltd.
  copyright: Copyright (c) 2024-2026 MangoAds Co., Ltd. All rights reserved.
license: Proprietary — All rights reserved. See LICENSE file for details.
---

# access-control

Mục tiêu: từ một file CSV (email → trang được xem) → cấu hình Cloudflare Access sao cho mỗi trang chỉ mở cho đúng email được liệt kê. Đăng nhập mặc định bằng **OTP** (người xem nhập email, nhận mã, vào).

Người dùng **non-tech**: họ chỉ cần điền/đưa CSV. Mọi thao tác API do agent làm.

## Trước khi bắt đầu

1. Đọc `site.config.json`. Cần `status.firstDeploy=true` (web đã online) và `status.zeroTrustEnabled=true`.
   - Zero Trust chưa bật → dẫn người dùng theo `setup-project/references/zero-trust-onboarding.md` rồi quay lại.
2. Lấy `domain`, `accountId`, mảng `pages` (để biết path hợp lệ), `loginMethod`.

## Quy trình

### Bước 1 — Lấy & kiểm tra CSV

- Nếu người dùng chưa có CSV, đưa họ mẫu [`assets/access-template.csv`](assets/access-template.csv) và giải thích cách điền (xem [`references/csv-schema.md`](references/csv-schema.md)).
- Đọc CSV, validate: email đúng định dạng, mỗi `pages` trỏ tới slug có thật trong `site.config.json`. Báo lỗi cụ thể nếu có dòng sai (ví dụ slug không tồn tại) thay vì lặng lẽ bỏ qua.

### Bước 2 — Gom thành map path → danh sách email

CSV là email→pages; lật lại thành **path → [emails]** vì Access cấu hình theo từng app/path. Một email nhiều trang thì xuất hiện ở nhiều path.

Ví dụ: `usr1@gmail.com, page1;page2` → `{ "/page1": ["usr1@..."], "/page2": ["usr1@..."] }`.

### Bước 3 — Đảm bảo login method OTP đã bật

Mặc định dùng OTP (One-Time PIN), không cần Google OAuth. Cách bật/kiểm tra qua API: xem [`references/cloudflare-access-api.md`](references/cloudflare-access-api.md) mục "Login method / OTP".

### Bước 4 — Provision Access app + policy theo path (idempotent + sync)

Với mỗi path, tạo hoặc cập nhật một Access application scope theo `domain + path` và một policy Allow include đúng danh sách email. Chi tiết endpoint + body + curl mẫu: [`references/cloudflare-access-api.md`](references/cloudflare-access-api.md).

Hai nguyên tắc bắt buộc:
- **Idempotent**: chạy lại nhiều lần không tạo trùng. Trước khi tạo, liệt kê app hiện có theo domain, nếu app cho path đó đã tồn tại thì cập nhật policy thay vì tạo mới.
- **Sync theo CSV (CSV là nguồn chân lý)**: email không còn trong CSV cho một path thì gỡ khỏi policy; path không còn ai thì cân nhắc xóa app (hỏi người dùng trước khi xóa). Đừng chỉ "thêm" — phải phản ánh đúng CSV hiện tại.

### Bước 5 — Lưu trạng thái + xác nhận

- Cập nhật `site.config.json`: `status.accessConfigured=true`, và (tùy chọn) lưu map path→app_id để lần sau cập nhật nhanh.
- Tóm tắt cho người dùng: trang nào giờ giới hạn cho ai, và họ đăng nhập thế nào (mở trang → nhập email → nhận mã qua mail → vào). Gợi ý họ tự test bằng cửa sổ ẩn danh.

## Quy ước path

- Dùng `/<slug>*` để phủ luôn trang con (ví dụ `/page1*` bao `/page1`, `/page1/abc`). Nếu cần chặt hơn, tách `/page1` và `/page1/*` (xem ghi chú trong reference).
- Path lấy từ mảng `pages` của config; đừng bịa path không có trong web.

## Lưu ý

- Bản Free Zero Trust giới hạn 50 user. Mỗi email đăng nhập = 1 seat. Cảnh báo người dùng nếu CSV vượt ~50 địa chỉ.
- Đây là thao tác nhạy cảm (mở/khóa quyền xem). Trước khi **xóa** app hay gỡ hàng loạt, xác nhận lại với người dùng.
- Nếu người dùng muốn login bằng Google thay vì OTP: cần tạo OAuth client bên Google Cloud (thủ công, ngoài API Cloudflare) — chỉ làm khi họ chủ động yêu cầu; mặc định OTP.
