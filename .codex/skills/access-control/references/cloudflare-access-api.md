# Cloudflare Access API — provision app + policy theo path

> ✅ **Logic này đã được hiện thực sẵn trong [`../scripts/sync-access.mjs`](../scripts/sync-access.mjs)** — luồng chính chỉ cần chạy script đó (xem SKILL.md). File này giải thích cơ chế + endpoint + body mẫu để agent hiểu / đối chiếu / sửa script khi cần. Schema API có thể đổi theo thời gian — nếu script lỗi vì tên trường, đối chiếu docs hiện hành (`https://developers.cloudflare.com/cloudflare-one/`) rồi cập nhật script.

## Khái niệm

- **Access Application** = `domain + path`. Để khóa từng trang, mỗi path là một app.
- **Policy** = luật quyết định ai vào được. Dùng action `allow` + rule `include` chứa danh sách email.
- **Login method (OTP)** = cách người xem xác thực; OTP gửi mã qua email, không cần IdP ngoài.

## Biến môi trường

```bash
set -a; . ./.env; set +a    # nạp CF_API_TOKEN, CF_ACCOUNT_ID từ .env ở gốc dự án
AUTH=(-H "Authorization: Bearer $CF_API_TOKEN")
ACC="https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID"
```

## 1. Login method / OTP

OTP (one-time PIN) là login method tích hợp sẵn ở cấp Access, không cần tạo IdP Google. Trên hầu hết tài khoản, OTP có sẵn sau khi onboard Zero Trust. Kiểm tra danh sách IdP:

```bash
curl -s "${AUTH[@]}" "$ACC/access/identity_providers"
```

Nếu cần thêm OTP rõ ràng, IdP loại one-time PIN có `type: "onetimepin"`:
```bash
curl -s "${AUTH[@]}" -X POST "$ACC/access/identity_providers" \
  -H "Content-Type: application/json" \
  -d '{"name":"OTP","type":"onetimepin"}'
```
> Nhiều tài khoản đã có sẵn onetimepin; nếu tạo báo trùng thì bỏ qua. Đối chiếu docs nếu field khác.

## 2. Liệt kê app hiện có (cho idempotent)

Trước khi tạo, lấy danh sách app để biết path nào đã có:

```bash
curl -s "${AUTH[@]}" "$ACC/access/apps"
```

So khớp theo `domain` (dạng `<site-domain>/<slug>*`). Nếu đã có app cho path đó → đi tới bước cập nhật policy (mục 4), KHÔNG tạo mới.

## 3. Tạo Access application cho một path

```bash
curl -s "${AUTH[@]}" -X POST "$ACC/access/apps" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "page1 - <projectName>",
    "type": "self_hosted",
    "domain": "<projectName>.pages.dev/page1*",
    "session_duration": "24h"
  }'
```

- `domain` gồm cả path + `*` để phủ trang con. Ví dụ `khach-abc.pages.dev/page1*`.
- Lưu lại `id` trả về (app_id) để gắn policy và để cập nhật sau (có thể ghi vào `site.config.json`).

> Lưu ý precedence: Cloudflare match path cụ thể nhất trước. Nếu sau này có app rộng `<domain>/*`, các app path hẹp vẫn được ưu tiên.

## 4. Tạo / cập nhật policy (Allow + include email)

Tạo policy cho app:

```bash
curl -s "${AUTH[@]}" -X POST "$ACC/access/apps/$APP_ID/policies" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "allow-emails-page1",
    "decision": "allow",
    "include": [
      { "email": { "email": "usr1@gmail.com" } },
      { "email": { "email": "usr3@gmail.com" } }
    ]
  }'
```

- `include` là OR: khớp một email là vào được.
- Cập nhật policy đã có: `PUT $ACC/access/apps/$APP_ID/policies/$POLICY_ID` với mảng `include` mới (toàn bộ danh sách email hiện tại theo CSV).

> Để dùng được OTP, đảm bảo login method onetimepin đang bật cho app (mặc định Access cho phép các IdP đã bật). Nếu app prompt sai cách, kiểm tra `allowed_idps` của app.

## 5. Logic đồng bộ (sync theo CSV)

Pseudo-code cho agent:

```
csvMap = parseCSV()                  # { "/page1": [emails], ... }
existingApps = GET /access/apps      # lọc theo domain của project

for each path, emails in csvMap:
    app = findApp(existingApps, path) or createApp(path)
    policy = getPolicy(app) or createPolicy(app)
    setIncludeEmails(policy, emails)   # PUT — ghi đè đúng danh sách CSV

# Dọn path không còn trong CSV:
for app in existingApps thuộc project:
    if app.path not in csvMap:
        hỏi người dùng → nếu đồng ý thì DELETE app
```

Điểm mấu chốt: **PUT toàn bộ danh sách email** (không chỉ POST thêm) để policy phản ánh đúng CSV → vừa idempotent vừa sync. Email bị xóa khỏi CSV sẽ biến mất khỏi include sau khi PUT.

## 6. Xóa app (khi path không còn ai)

```bash
curl -s "${AUTH[@]}" -X DELETE "$ACC/access/apps/$APP_ID"
```

⚠️ Xóa app = trang đó trở lại public (hoặc theo app rộng hơn nếu có). Luôn xác nhận với người dùng trước khi xóa.

## Kiểm thử

Sau khi cấu hình, dùng Policy Tester trong dashboard (Zero Trust → Access → app → Policies → Policy tester) hoặc mở trang bằng cửa sổ ẩn danh: phải hiện màn hình nhập email → nhập email được phép → nhận mã qua mail → vào được; email ngoài danh sách → bị từ chối.

## Lỗi thường gặp

| Triệu chứng | Xử lý |
|---|---|
| 403 khi gọi API | Token thiếu quyền Access: Apps and Policies / Organizations-IdP-Groups: Edit. |
| "organization not found" | Chưa onboard Zero Trust — quay lại zero-trust-onboarding.md. |
| Mở trang không hiện màn hình đăng nhập | App `domain`/path sai, hoặc trang nằm ngoài scope. Kiểm tra lại `<domain>/<slug>*`. |
| Hiện đăng nhập nhưng ai cũng vào được | Policy include đang là "everyone" hoặc OTP không kèm danh sách email — sửa include về đúng email. |
