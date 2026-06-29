# Quyền chính xác cho API token

Token cần đủ quyền để: deploy Pages, tạo/sửa Access app + policy, và sửa DNS (chỉ khi dùng custom domain). Không hơn.

## Danh sách permission cần chọn

Khi tạo Custom Token, thêm các dòng sau (mỗi dòng để mức **Edit**):

| Loại | Permission group | Mức | Dùng cho |
|---|---|---|---|
| Account | **Cloudflare Pages** | Edit | tạo project, deploy web |
| Account | **Access: Apps and Policies** | Edit | tạo Access app + policy phân quyền page |
| Account | **Access: Organizations, Identity Providers, and Groups** | Edit | bật/cấu hình login method (OTP), group email |
| Zone | **DNS** | Edit | chỉ cần nếu gắn tên miền riêng; bỏ nếu chỉ xài `.pages.dev` |

**Account Resources**: Include → chọn đúng account của người dùng.
**Zone Resources** (nếu có dòng DNS): Include → All zones, hoặc chọn zone của tên miền riêng.

## Vì sao không lấy Global API Key

- Global API Key toàn quyền: đổi billing, xóa tài khoản, mọi zone, mọi thứ. Đưa cho tool tự động là rủi ro rất lớn.
- API Token giới hạn được phạm vi, đặt được ngày hết hạn (TTL), thậm chí giới hạn IP. Lộ thì chỉ ảnh hưởng đúng vài quyền và thu hồi riêng được mà không động tới phần còn lại của tài khoản.

## Kiểm tra token sau khi tạo

```bash
source .cloudflare-secret
curl -s "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CF_API_TOKEN"
# success=true và status="active" là đạt
```

Nếu một bước sau này báo lỗi 403/authentication, gần như chắc chắn token thiếu một trong các quyền trên — quay lại bổ sung.
