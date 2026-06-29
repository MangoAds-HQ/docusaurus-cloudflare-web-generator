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

### Bước 1 — Đảm bảo thư mục `access-control/` ở gốc dự án

Người dùng khai báo quyền trong **file CSV ở gốc dự án**, KHÔNG phải trong thư mục skill — để họ sửa cho tiện. Chạy script tạo thư mục + file mẫu (idempotent, không ghi đè nếu đã có):

```bash
bash .codex/skills/access-control/scripts/init-access-control.sh
```

Nó tạo (nếu chưa có): `access-control/access.csv` (file người dùng sửa) + `access-control/README.txt` (hướng dẫn). Bảo người dùng mở `access-control/access.csv`, điền email + trang. Cách điền: xem [`references/csv-schema.md`](references/csv-schema.md).

> Nếu người dùng đã có sẵn file CSV/Excel của riêng họ, copy nội dung vào `access-control/access.csv` (hoặc trỏ `--csv <path>` khi chạy script ở bước 2).

### Bước 2 — Xem trước (dry-run) để bắt lỗi

Chạy thử KHÔNG đổi gì trên Cloudflare — script tự validate CSV (email, slug có thật trong `site.config.json`) và in những gì sẽ làm:

```bash
node .codex/skills/access-control/scripts/sync-access.mjs --dry-run
```

Nếu báo lỗi CSV (email sai, slug không tồn tại…), bảo người dùng sửa `access-control/access.csv` rồi chạy lại. Đừng áp dụng khi còn lỗi.

### Bước 3 — Áp dụng (provision + sync)

```bash
node .codex/skills/access-control/scripts/sync-access.mjs
```

Script lo trọn phần Cloudflare: bật OTP nếu chưa có, với mỗi trang tạo/cập nhật Access app (`domain + /slug*`) + policy Allow include đúng danh sách email. Nó **idempotent** (chạy lại không tạo trùng) và **sync theo CSV** (PUT toàn bộ danh sách → ai bị xóa khỏi CSV cũng mất quyền). Chi tiết cơ chế/endpoint: [`references/cloudflare-access-api.md`](references/cloudflare-access-api.md).

### Bước 4 — Dọn trang thừa (chỉ khi cần, có xác nhận)

Nếu một trang từng phân quyền giờ không còn dòng nào trong CSV, mặc định script **chỉ cảnh báo** chứ không xóa (an toàn). Sau khi **xác nhận với người dùng** rằng muốn mở lại trang đó cho công khai:

```bash
node .codex/skills/access-control/scripts/sync-access.mjs --prune
```

⚠️ `--prune` xóa Access app của trang thừa → trang đó trở lại public. Luôn hỏi người dùng trước.

### Bước 5 — Lưu trạng thái + xác nhận

- Cập nhật `site.config.json`: `status.accessConfigured=true`.
- Tóm tắt cho người dùng: trang nào giờ giới hạn cho ai, và họ đăng nhập thế nào (mở trang → nhập email → nhận mã qua mail → vào). Gợi ý họ tự test bằng cửa sổ ẩn danh.

## Quy ước path

- Dùng `/<slug>*` để phủ luôn trang con (ví dụ `/page1*` bao `/page1`, `/page1/abc`). Nếu cần chặt hơn, tách `/page1` và `/page1/*` (xem ghi chú trong reference).
- Path lấy từ mảng `pages` của config; đừng bịa path không có trong web.

## Lưu ý

- Bản Free Zero Trust giới hạn 50 user. Mỗi email đăng nhập = 1 seat. Cảnh báo người dùng nếu CSV vượt ~50 địa chỉ.
- Đây là thao tác nhạy cảm (mở/khóa quyền xem). Trước khi **xóa** app hay gỡ hàng loạt, xác nhận lại với người dùng.
- Nếu người dùng muốn login bằng Google thay vì OTP: cần tạo OAuth client bên Google Cloud (thủ công, ngoài API Cloudflare) — chỉ làm khi họ chủ động yêu cầu; mặc định OTP.
