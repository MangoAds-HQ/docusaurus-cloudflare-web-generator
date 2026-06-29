# Hướng dẫn người dùng đăng ký Cloudflare & lấy token

Phần này người dùng phải tự thao tác trên trình duyệt — agent không làm thay được. Nhiệm vụ của agent: dẫn từng bước thật rõ, chờ họ đưa lại Account ID + API token.

## A. Tạo tài khoản (bỏ qua nếu đã có)

1. Vào https://dash.cloudflare.com/sign-up
2. Nhập email + mật khẩu, xác nhận email.
3. Đăng nhập vào dashboard. (Không cần thêm thẻ tín dụng, không cần mua gì — bản miễn phí đủ dùng.)

## B. Lấy Account ID

1. Sau khi đăng nhập, vào mục **Workers & Pages** ở menu trái.
2. Cột bên phải có dòng **Account ID** — bấm copy.
3. Đưa chuỗi đó cho agent.

(Nếu không thấy: vào bất kỳ trang nào trong dashboard, Account ID thường nằm ở sidebar phải hoặc trong URL dạng `dash.cloudflare.com/<account-id>/...`.)

## C. Tạo API token có giới hạn quyền

> ⚠️ **Tuyệt đối không đưa "Global API Key".** Đó là chìa khóa vạn năng của cả tài khoản — lộ ra là mất sạch. Chỉ tạo **API Token** với đúng vài quyền cần thiết. Nếu lộ, nó chỉ làm được đúng mấy việc đó và có thể thu hồi riêng.

Các bước:

1. Bấm vào avatar góc trên phải → **My Profile**.
2. Menu trái chọn **API Tokens**.
3. Bấm **Create Token**.
4. Kéo xuống chọn **Create Custom Token** → **Get started**.
5. Đặt tên token, ví dụ `web-builder-token`.
6. Thêm các quyền (Permissions) — xem danh sách chính xác trong [`api-token-scopes.md`](api-token-scopes.md). Mỗi dòng chọn nhóm + mức **Edit**.
7. Phần **Account Resources**: chọn đúng account của họ.
8. (Tùy chọn nhưng nên) phần **TTL**: đặt ngày hết hạn để an toàn hơn.
9. Bấm **Continue to summary** → **Create Token**.
10. **Token chỉ hiện đúng một lần.** Copy ngay và đưa cho agent. Nếu lỡ mất, phải tạo lại token mới.

## D. Agent nhận token

Khi người dùng dán token + Account ID, agent ghi vào `.env` ở gốc dự án (xem SKILL.md), kiểm tra token sống bằng endpoint verify, rồi tiếp tục. Không in lại token.

## Nếu người dùng kẹt

- Không tìm thấy "Create Custom Token": cuộn xuống cuối trang API Tokens, phần "Custom token" có nút "Get started".
- Token verify trả về lỗi: thường do thiếu quyền hoặc chọn sai account resource → tạo lại theo `api-token-scopes.md`.
