# Hướng dẫn lấy "chìa khóa" Cloudflare (dành cho người không rành kỹ thuật)

Tài liệu này hướng dẫn bạn **tự lấy thông tin kết nối tới Cloudflare** để trợ lý (Claude) thay bạn dựng web, đăng lên mạng và phân quyền người xem. Bạn **không cần biết lập trình** — chỉ cần làm theo từng bước bấm chuột.

> Toàn bộ phần kỹ thuật do trợ lý làm. Việc của bạn chỉ là: tạo tài khoản Cloudflare, lấy "chìa khóa", và dán cho trợ lý.

---

## 1. "Chìa khóa" này để làm gì?

Web của bạn được đặt trên **Cloudflare** (một dịch vụ miễn phí giúp web chạy nhanh và an toàn). Để trợ lý thao tác thay bạn, nó cần một "chìa khóa" chứng minh đây là tài khoản của bạn.

Có **2 loại chìa khóa**, dùng cho 2 việc khác nhau:

| Việc bạn muốn làm | Cần loại nào | Khó hay dễ |
|---|---|---|
| Đưa web lên mạng (deploy) | Đăng nhập 1 lần bằng nút bấm | 🟢 Rất dễ |
| **Giới hạn ai được xem trang nào** | **API token** (tài liệu này) | 🟡 Cần vài bước |

👉 Nếu bạn **chỉ muốn web công khai cho mọi người xem**, bạn **không cần đọc tiếp** — chỉ cần làm theo **Cách A** bên dưới.
👉 Nếu bạn muốn **chặn/cho phép từng người xem từng trang**, bạn cần **API token** ở **Cách B**.

---

## 2. Cách A — Đăng nhập nhanh (chỉ để đưa web lên mạng)

Đây là cách dễ nhất, **không cần token**. Khi trợ lý cần, nó sẽ chạy lệnh và **một trang web Cloudflare tự mở ra**. Bạn chỉ cần:

1. Bấm nút **"Allow"** (Cho phép) màu xanh.
2. Xong. Quay lại nói chuyện với trợ lý.

Vậy là đủ để web của bạn lên mạng. Nếu sau này bạn muốn phân quyền, hãy làm thêm **Cách B**.

---

## 3. Cách B — Lấy API token (để phân quyền người xem)

Phần này cần thiết **chỉ khi** bạn muốn giới hạn người xem. Bình tĩnh làm theo từng bước, mỗi bước chỉ là bấm chuột.

### Bước B1 — Tạo tài khoản Cloudflare (bỏ qua nếu đã có)

1. Mở trình duyệt, vào: **https://dash.cloudflare.com/sign-up**
2. Nhập email + mật khẩu → bấm đăng ký → mở email xác nhận.
3. Đăng nhập vào trang quản lý (gọi là "dashboard").

> 💳 **Không cần thẻ tín dụng, không mất phí.** Bản miễn phí đủ dùng. (Một số bước có thể hỏi thẻ để "xác minh" nhưng **không trừ tiền** — bạn cứ yên tâm.)

### Bước B2 — Lấy "Account ID"

"Account ID" là mã số của tài khoản bạn (giống số nhà).

1. Ở menu bên trái, bấm **Workers & Pages**.
2. Nhìn cột bên phải, tìm dòng **Account ID** → bấm nút copy.
3. Giữ lại để lát nữa đưa trợ lý.

> Mẹo: nếu không thấy, nhìn lên thanh địa chỉ trình duyệt — nó có dạng `dash.cloudflare.com/`**`mã-dài-này`**`/...`. Mã dài đó chính là Account ID.

### Bước B3 — Tạo API token (phần quan trọng nhất)

> ⚠️ **TUYỆT ĐỐI không dùng "Global API Key".** Đó là chìa khóa vạn năng mở được mọi thứ trong tài khoản — lỡ lộ là mất sạch. Chúng ta chỉ tạo **API Token** với **đúng vài quyền nhỏ** cần thiết. Lộ thì cũng chỉ làm được đúng mấy việc đó, và thu hồi riêng được.

1. Bấm vào **ảnh đại diện** (góc trên bên phải) → chọn **My Profile**.
2. Menu trái → **API Tokens** → bấm nút **Create Token**.
3. Kéo xuống cuối, mục **Custom token** → bấm **Get started**.
4. Ở ô **Token name**, đặt tên dễ nhớ, ví dụ: `web-cua-toi`.
5. Mục **Permissions** (Quyền) — thêm các dòng sau. Mỗi dòng có 3 ô; chọn đúng như bảng, ô cuối luôn để **Edit**:

   | Ô 1 (loại) | Ô 2 (quyền) | Ô 3 (mức) |
   |---|---|---|
   | Account | **Cloudflare Pages** | Edit |
   | Account | **Access: Apps and Policies** | Edit |
   | Account | **Access: Organizations, Identity Providers, and Groups** | Edit |

   *(Bấm "+ Add more" để thêm dòng mới cho đủ 3 dòng.)*

6. Mục **Account Resources**: chọn **Include** → chọn **tài khoản của bạn** trong danh sách.
7. (Nên làm) Mục **TTL**: đặt ngày hết hạn (vd 1 năm) cho an toàn.
8. Bấm **Continue to summary** → kiểm tra lại → bấm **Create Token**.
9. ⚠️ **Token chỉ hiện ra ĐÚNG MỘT LẦN.** Bấm copy ngay. Nếu lỡ đóng trang mà chưa copy, phải tạo token mới.

> Token trông giống một chuỗi chữ và số dài (ví dụ bắt đầu bằng `cfat_...`). Cứ copy **toàn bộ**, không cắt xén.

### Bước B4 — Bật "Zero Trust" (chỉ làm 1 lần)

Đây là phần giúp Cloudflare biết cách hỏi mật mã người xem.

1. Ở dashboard, menu trái → bấm **Zero Trust**.
2. Lần đầu vào sẽ có màn hình chào. Nó yêu cầu đặt một **team name** — đây là phần đầu của địa chỉ đăng nhập, ví dụ `congtyabc` → sẽ thành `congtyabc.cloudflareaccess.com`.
   - Đặt **chữ thường, không dấu, không khoảng trắng**.
3. Chọn gói **Free** (miễn phí, tối đa 50 người xem).
4. Hoàn tất.

---

## 4. Đưa "chìa khóa" cho trợ lý thế nào?

Sau khi có **Account ID** (Bước B2) và **API token** (Bước B3), bạn chỉ cần **dán chúng vào khung chat** với trợ lý và nói "đây là token của tôi".

Trợ lý sẽ:
- Lưu token vào một file ẩn tên `.env` (được bảo vệ, **không bị đẩy lên mạng**).
- **Không bao giờ in token đầy đủ ra màn hình** — chỉ hiện 4 ký tự cuối để xác nhận.
- Tự kiểm tra token sống và làm tiếp phần kỹ thuật.

---

## 5. An toàn — vài điều nên nhớ

- ✅ Token = mật khẩu. **Không gửi cho người lạ**, không đăng lên mạng xã hội, không chụp màn hình chia sẻ.
- ✅ Nếu nghi token bị lộ: vào **My Profile → API Tokens**, bấm token đó → **Roll** (đổi mới) hoặc **Delete** (xóa). Rồi tạo lại token mới và đưa trợ lý.
- ✅ Token nên có **ngày hết hạn** (đã hướng dẫn ở Bước B3 mục TTL).
- ✅ File `.env` chứa token đã được trợ lý cấu hình **không đẩy lên mạng** (gitignore). Đừng tự ý copy nó đi nơi khác.

---

## 6. Sự cố thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| Không thấy nút "Create Custom Token" | Cuộn xuống **cuối** trang API Tokens, mục **Custom token** có nút **Get started**. |
| Trợ lý báo token "không có quyền" (403) | Token thiếu một dòng quyền ở Bước B3 → tạo lại token, thêm đủ 3 dòng. |
| Tên web bị thêm hậu tố lạ (vd `ten-abc.pages.dev`) | Bình thường — tên bạn chọn đã có người dùng, Cloudflare tự thêm vài ký tự cho khác biệt. Web vẫn chạy đúng. |
| Mở trang bị hỏi đăng nhập | Đúng rồi — trang đó đang được **phân quyền**. Nhập email được cấp phép → nhận **mã 6 số** qua mail → nhập vào là xem được. |

---

## 7. Sau khi xong thì làm gì?

Nói với trợ lý bằng lời thường, ví dụ:
- *"Tạo web cho tôi"* → trợ lý dựng web.
- *"Sửa trang giới thiệu thành..."* → trợ lý cập nhật nội dung.
- *"Chỉ cho mấy email này xem trang báo cáo"* → trợ lý phân quyền.

Bạn **luôn mô tả bằng lời** — phần Markdown, lệnh, API… để trợ lý lo. 🎉
