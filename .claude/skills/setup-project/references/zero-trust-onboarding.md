# Bật Zero Trust + đặt team name

Access (phân quyền page bằng email) chỉ hoạt động sau khi tài khoản đã onboard Zero Trust và đặt **team name** một lần. Đây thường là bước thủ công lần đầu trên dashboard.

> ⚠️ **Cần verify:** việc onboard Zero Trust lần đầu (đặt team name) có thể CHƯA có API hoàn chỉnh. Đến thời điểm viết skill, cách chắc chắn là làm thủ công 1 lần trên dashboard. Agent NÊN thử kiểm tra qua API trước (xem cuối file); nếu không được thì rơi về hướng dẫn thủ công dưới đây. Đừng hứa "tự động 100%" cho người dùng ở bước này.

## Hướng dẫn thủ công (đường chắc ăn)

1. Trong dashboard Cloudflare, menu trái chọn **Zero Trust**.
2. Lần đầu vào sẽ có màn hình onboarding. Đặt một **team name** (ví dụ `khachabc`) — đây là phần đầu của URL đăng nhập, dạng `khachabc.cloudflareaccess.com`. Đặt chữ thường, không dấu.
3. Chọn gói **Free** (tối đa 50 user, đủ dùng). Có thể bị hỏi thông tin thẻ để xác minh nhưng gói Free không tính phí — báo trước cho người dùng để họ yên tâm.
4. Hoàn tất. Giờ tài khoản đã sẵn sàng cho `access-control`.

## Kiểm tra trạng thái qua API (agent thử trước)

```bash
source .cloudflare-secret
curl -s "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/access/organizations" \
  -H "Authorization: Bearer $CF_API_TOKEN"
```

- Trả về org có `name`/`auth_domain` → Zero Trust đã bật, đánh dấu `zeroTrustEnabled: true`.
- Trả về rỗng hoặc lỗi "organization not found" → chưa onboard, dẫn người dùng làm thủ công ở trên.

> Việc tạo organization qua API (`POST .../access/organizations`) có thể khả dụng tùy thời điểm. Agent có thể thử, nhưng nếu thất bại thì dùng hướng dẫn thủ công, đừng chặn cả luồng vì bước này.

## Login method mặc định: OTP

Dự án mặc định dùng **One-Time PIN (OTP)** để người xem đăng nhập bằng email (nhận mã qua mail). OTP không cần cấu hình Google OAuth, gần như zero-config — phù hợp non-tech. Cấu hình OTP nằm trong skill `access-control`.
