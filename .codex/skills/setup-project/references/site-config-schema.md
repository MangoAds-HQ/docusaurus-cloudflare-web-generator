# site.config.json — file cấu hình dùng chung

Đây là "mảnh keo" nối cả 4 skill. `setup-project` tạo ra, ba skill kia đọc/ghi. Nó lưu mọi thứ cần biết về dự án + trạng thái đang ở bước nào (để resume được).

## Vị trí

Đặt ở gốc thư mục làm việc của dự án: `./site.config.json`.
Token KHÔNG nằm ở đây — token ở `./.env` (đã gitignore).

## Schema

```json
{
  "projectName": "khach-abc",
  "accountId": "0123456789abcdef0123456789abcdef",
  "domain": "khach-abc.pages.dev",
  "useCustomDomain": false,
  "customDomain": null,
  "loginMethod": "otp",
  "contentDir": "docs",
  "status": {
    "toolchainReady": true,
    "tokenCreated": true,
    "zeroTrustEnabled": false,
    "webCreated": false,
    "firstDeploy": false,
    "accessConfigured": false
  },
  "pages": [],
  "updatedAt": "2026-06-28T00:00:00Z"
}
```

## Giải thích trường

| Trường | Ý nghĩa |
|---|---|
| `projectName` | Tên Pages project, **không đổi được sau khi tạo**. Chữ thường / số / gạch ngang. |
| `accountId` | Cloudflare Account ID (cũng có trong secret, lặp ở đây cho tiện đọc). |
| `domain` | URL chính của web. Mặc định `<projectName>.pages.dev`. |
| `useCustomDomain` / `customDomain` | Nếu gắn tên miền riêng. |
| `loginMethod` | `otp` (mặc định) hoặc `google`. |
| `contentDir` | Thư mục chứa nội dung Docusaurus (`docs` hoặc `pages`). |
| `status.*` | Cờ đánh dấu đã qua bước nào — để skill biết resume từ đâu. |
| `pages` | Danh sách page đã tạo + đường dẫn, để `access-control` map. Xem dưới. |

## Mảng `pages`

Mỗi page web tương ứng một entry, để `access-control` biết path nào cần khóa:

```json
"pages": [
  { "slug": "page1", "path": "/page1", "title": "Trang 1" },
  { "slug": "page2", "path": "/page2", "title": "Trang 2" }
]
```

`create-web` và `update-content` cập nhật mảng này khi tạo/sửa page. `access-control` đọc nó để dựng Access app theo path.

## Quy ước cập nhật

- Skill nào hoàn thành một bước thì set cờ `status` tương ứng = true và cập nhật `updatedAt`.
- Trước khi làm việc gì, skill đọc `site.config.json` để biết đã có gì, tránh hỏi lại người dùng những thứ đã biết.
- Nếu file không tồn tại → người dùng chưa chạy `setup-project`, hãy dẫn họ chạy skill đó trước.
