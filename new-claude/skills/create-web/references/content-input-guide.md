# Lấy nội dung từ người dùng non-tech

Người dùng không biết viết Markdown. Đừng đưa họ một thư mục trống và bảo "điền vào". Thay vào đó, **phỏng vấn ngắn** rồi agent tự sinh Markdown.

## Cách hỏi

Hỏi theo nhóm, mỗi lần một câu, đừng dồn. Ví dụ trình tự:

1. "Web này về cái gì? Tên hiển thị và một câu mô tả ngắn?"
   → dùng cho `title` + `tagline` trong `docusaurus.config.js`.
2. "Bạn muốn web có những trang nào? Cứ liệt kê tên trang." 
   → mỗi trang thành một file `.md`, một entry trong `pages`.
3. Với từng trang: "Trang **X** cần nội dung gì? Bạn cứ gõ thô, gạch đầu dòng, hoặc dán đoạn văn — tôi lo phần định dạng."
   → agent chuyển thành Markdown gọn gàng.

## Các cách người dùng đưa liệu

Chấp nhận mọi định dạng thô, agent chuẩn hóa:

- Gõ trực tiếp text / gạch đầu dòng trong chat.
- Dán đoạn văn dài → agent chia heading, đoạn, danh sách hợp lý.
- Đưa file có sẵn (`.docx`, `.txt`, `.md`, bảng) → agent đọc và chuyển.
- Đưa ảnh có chữ → agent đọc nội dung và soạn lại.

## Agent sinh Markdown thế nào

Mỗi trang → `docs/<slug>.md`:

```markdown
---
id: <slug>
title: <Tiêu đề trang>
slug: /<slug>
---

# <Tiêu đề trang>

<Nội dung đã định dạng từ mô tả của người dùng>
```

Quy tắc đặt `slug`:
- Chữ thường, không dấu, dùng gạch ngang. "Giới thiệu công ty" → `gioi-thieu`.
- `slug` = URL của trang (`/gioi-thieu`) = path mà `access-control` sẽ khóa. Đặt ngắn gọn, ổn định.
- Ghi lại slug vào `site.config.json` ngay khi tạo.

## Mẹo trải nghiệm

- Sau khi sinh xong một trang, mô tả lại bằng lời cho người dùng ("Trang Giới thiệu giờ có 3 mục: ...") để họ duyệt, thay vì bắt họ đọc Markdown.
- Không hỏi quá nhiều một lúc. Tạo được khung tối thiểu rồi cho họ xem web sống trước, nội dung bổ sung sau qua `update-content`.
