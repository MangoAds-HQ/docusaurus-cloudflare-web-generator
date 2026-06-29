# Schema CSV phân quyền

CSV là cách người dùng non-tech khai báo "ai xem được trang nào". Schema cố định, đơn giản nhất có thể. CSV là **nguồn chân lý** — agent đồng bộ Access đúng theo nó.

## Định dạng

Đúng 2 cột, có dòng tiêu đề:

```csv
email,pages
usr1@gmail.com,page1;page2
usr2@gmail.com,page2
usr3@gmail.com,page1;page3
```

| Cột | Ý nghĩa |
|---|---|
| `email` | Một địa chỉ email được cấp quyền. Mỗi dòng một email. |
| `pages` | Danh sách **slug** trang mà email này được xem, ngăn nhau bằng dấu chấm phẩy `;`. |

## Quy tắc

- `pages` dùng **slug** (như `page1`, `gioi-thieu`) — đúng slug đã định nghĩa lúc tạo web, có trong `site.config.json`. Không dùng URL đầy đủ, không dùng dấu `/`.
- Một email muốn xem nhiều trang → liệt kê các slug cách nhau bằng `;` trong cùng một dòng: `page1;page2;page3`.
- Không phân biệt hoa thường ở email, nhưng nên giữ nguyên người dùng nhập.
- Dòng trống bị bỏ qua.

## Validate trước khi áp dụng

Agent kiểm tra và báo lỗi rõ ràng (không lặng lẽ bỏ qua):

1. Email sai định dạng → chỉ ra dòng nào.
2. Slug trong `pages` không tồn tại trong `site.config.json` → báo "trang `xyz` không có trên web; các trang hiện có: ...".
3. Trùng email ở nhiều dòng → gộp lại (union các trang) và báo cho người dùng biết đã gộp.

## Ý nghĩa đồng bộ

- Email + trang **có trong CSV** → được cấp quyền.
- Email từng có quyền nhưng **không còn trong CSV** cho trang đó → bị **gỡ** quyền (sync, không phải chỉ thêm).
- Muốn cấm ai → xóa họ khỏi CSV rồi chạy lại skill.

## Mẹo cho người dùng

- Họ có thể sửa CSV bằng Excel / Google Sheets rồi xuất `.csv`. Nhắc xuất đúng định dạng CSV (UTF-8), không phải `.xlsx`.
- Nếu họ quen Excel hơn, vẫn nhận `.xlsx` được — agent đọc rồi tự hiểu 2 cột `email`, `pages`.
