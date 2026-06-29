# Hướng dẫn sử dụng — Tạo web, viết tài liệu & phân quyền

Bộ công cụ này giúp **người không rành kỹ thuật** tự dựng một website tài liệu và giới hạn ai được xem trang nào — mà **không cần viết code, không cần biết Markdown hay API**. Bạn chỉ cần *mô tả bằng lời*, phần kỹ thuật để trợ lý (agent) lo.

> Bạn nói chuyện với trợ lý bằng tiếng Việt thường ngày. Ví dụ: *"Tạo cho tôi web có trang Giới thiệu và Bảng giá, chỉ cho mấy khách trong danh sách này xem."*

---

## 1. Pipeline làm gì? (toàn cảnh)

```
   Bạn mô tả bằng lời
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│  1. setup-project   →  Chuẩn bị: kết nối Cloudflare, lấy mã   │
│                        khoá (token), bật bảo mật Zero Trust   │
│  2. create-web      →  Dựng website + sinh nội dung từ mô tả  │
│                        của bạn, đưa web lên mạng (online)     │
│  3. update-content  →  Sửa/thêm trang, đăng nội dung mới      │
│  4. access-control  →  Phân quyền: ai được xem trang nào      │
└─────────────────────────────────────────────────────────────┘
          │
          ▼
   Web online tại  https://<tên-dự-án>.pages.dev
```

Bạn **không cần nhớ 4 bước trên**. Chỉ cần nói mục tiêu, trợ lý tự biết đang ở đâu và chạy đúng bước còn thiếu (đó là việc của orchestrator `web-pipeline`).

---

## 2. Bắt đầu nhanh

Mở trợ lý trong thư mục dự án này và nói mục tiêu của bạn. Ví dụ theo từng tình huống:

| Bạn muốn… | Chỉ cần nói (ví dụ) |
|---|---|
| Làm web lần đầu | *"Làm cho tôi một website tài liệu mới."* |
| Tạo tài liệu mới | *"Thêm trang Hướng dẫn cài đặt, nội dung gồm các bước A, B, C."* |
| Sửa nội dung | *"Đổi đoạn giới thiệu ở trang chủ thành…"* |
| Phân quyền | *"Chỉ cho 3 email này xem trang Bảng giá."* |
| Vừa tạo vừa khoá | *"Tạo trang Báo cáo nội bộ và chỉ cho nhóm kế toán xem."* |

Trợ lý sẽ đọc trạng thái dự án (`site.config.json`), hỏi lại vài điều tối thiểu, rồi làm.

---

## 3. Chi tiết từng bước

### Bước 1 — Chuẩn bị (`setup-project`)

Chỉ làm **một lần** cho mỗi dự án. Trợ lý sẽ:

1. Kiểm tra máy bạn đã có công cụ cần thiết chưa (Node.js…).
2. Hướng dẫn bạn **đăng ký Cloudflare miễn phí** và **tạo mã khoá (API token)** — trợ lý chỉ rõ từng nút bấm trên trình duyệt.
3. Bật **Zero Trust** (lớp bảo mật để sau này phân quyền được).
4. Tạo các file cấu hình: `site.config.json`, `.env`.

> 🔑 **Việc bạn cần tự làm:** thao tác đăng ký + lấy token trên web Cloudflare. Phần còn lại trợ lý làm.

### Bước 2 — Dựng web + viết tài liệu (`create-web`)

1. Trợ lý hỏi bạn muốn web có những trang nào, mỗi trang nói gì.
2. **Bạn mô tả bằng lời** hoặc gạch đầu dòng → trợ lý tự chuyển thành trang web đúng chuẩn.
3. Đưa web lên mạng và gửi bạn đường link `https://<tên-dự-án>.pages.dev` để mở thử.

### Bước 3 — Cập nhật nội dung (`update-content`)

Mỗi khi cần **thêm trang / sửa chữ / đăng bài mới**, chỉ cần mô tả thay đổi. Trợ lý sửa và đẩy bản mới lên. Bạn không phải đụng vào file nào.

### Bước 4 — Phân quyền người xem (`access-control`)

Quyết định **ai được xem trang nào**:

1. Bạn điền một bảng đơn giản (file `access-control/access.csv`) gồm 2 cột:

   ```csv
   email,pages
   khach1@gmail.com,bang-gia;bao-cao
   khach2@gmail.com,bang-gia
   ```

   - Cột `email`: địa chỉ email người được xem.
   - Cột `pages`: tên các trang (slug) họ được xem, nhiều trang ngăn nhau bằng dấu `;`.
   - Có thể sửa bằng Excel/Google Sheets rồi lưu lại dạng `.csv` (UTF-8).

2. Trợ lý kiểm tra trước (`--dry-run`) rồi áp dụng. Người xem sẽ **đăng nhập bằng mã OTP** gửi qua email — không cần tài khoản gì thêm.

3. Ai bị xoá khỏi bảng → tự động mất quyền xem ở lần cập nhật sau.

> ⚠️ Bản Cloudflare miễn phí giới hạn ~50 người xem. Nếu danh sách vượt 50 email, trợ lý sẽ nhắc bạn.

---

## 4. Các file quan trọng (trợ lý quản, bạn chỉ cần biết)

| File / thư mục | Vai trò | Bạn có sửa không? |
|---|---|---|
| `site.config.json` | Cấu hình + trạng thái dự án (tên, URL, danh sách trang) | Không — trợ lý tự cập nhật |
| `.env` | Chứa mã khoá Cloudflare. **Bí mật, không chia sẻ** | Không |
| `<tên-dự-án>/` | Mã nguồn website | Không |
| `access-control/access.csv` | Bảng phân quyền email → trang | **Có** — bạn điền danh sách ở đây |

> 🔒 **Bảo mật:** Mã khoá chỉ nằm trong `.env`, không bao giờ in ra màn hình hay đưa lên mạng. File `.env` đã được loại khỏi git tự động.

---

## 5. Câu hỏi thường gặp

**Tôi không biết viết Markdown / code, dùng được không?**
Được. Bạn chỉ mô tả bằng lời, trợ lý lo phần kỹ thuật.

**Đổi nội dung xong bao lâu thì web cập nhật?**
Thường vài chục giây đến 1–2 phút để lan truyền. Mở lại link để xem.

**Phân quyền rồi nhưng tôi vẫn mở được trang công khai?**
Thử bằng **cửa sổ ẩn danh** (incognito) để không bị nhớ đăng nhập cũ.

**Muốn mở lại một trang cho công khai (bỏ giới hạn)?**
Nói với trợ lý — trợ lý sẽ gỡ phân quyền trang đó (có xác nhận trước khi làm).

**Web bị lỗi khi cập nhật?**
Thường do nội dung có chỗ chưa hợp lệ. Trợ lý sẽ báo và sửa trước khi đẩy lên, không đưa bản lỗi ra ngoài.

---

## 6. Mặc định của hệ thống

- Triển khai bằng **direct upload** (không cần GitHub).
- Đăng nhập xem trang bằng **mã OTP qua email** (không cần Google).
- Tên miền miễn phí dạng `<tên-dự-án>.pages.dev`.

---

*Tài liệu dành cho người dùng cuối. Chi tiết kỹ thuật của từng skill nằm trong `.claude/skills/<tên-skill>/SKILL.md`.*
