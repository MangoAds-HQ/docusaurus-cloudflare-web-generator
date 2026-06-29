# Build & redeploy

Web đã tồn tại từ `create-web`. Đây chỉ là rebuild + đẩy bản mới. Không tạo lại project.

## Chuẩn bị

```bash
source .cloudflare-secret      # đứng ở gốc dự án; nếu đang trong thư mục project thì source ../.cloudflare-secret
export CLOUDFLARE_API_TOKEN=$CF_API_TOKEN
export CLOUDFLARE_ACCOUNT_ID=$CF_ACCOUNT_ID
```

## Build

```bash
cd <projectName>
npm run build      # output ra ./build
```

Nếu build báo lỗi, sửa trước (xem mục lỗi thường gặp). Đừng deploy bản build hỏng.

## Deploy

```bash
npx wrangler pages deploy build --project-name <projectName> --branch main
```

- `--branch main` đẩy lên môi trường production (`<projectName>.pages.dev`).
- Lệnh in URL deployment. Bản production luôn ở `<projectName>.pages.dev`.

## Bằng REST API (nếu cần script hóa sau)

> 🔧 Để agent dựng sau theo yêu cầu chủ dự án. Tương tự deploy-first: dùng direct-upload flow hoặc trigger deployment qua `POST /accounts/{account_id}/pages/projects/{name}/deployments`. Khuyến nghị vẫn dùng wrangler cho gọn.

## Lỗi thường gặp

| Triệu chứng | Nguyên nhân & cách xử |
|---|---|
| `npm run build` lỗi frontmatter | Thiếu/sai `---` hoặc trường `id`/`slug` trong file `.md` mới sửa. |
| Build lỗi "broken link" | Link nội bộ trỏ tới trang không tồn tại. Sửa hoặc bỏ link. |
| Deploy 403 | Token thiếu quyền **Cloudflare Pages: Edit**. |
| Web vẫn hiện bản cũ | Trình duyệt cache, hoặc bản mới chưa lan truyền — chờ 1-2 phút, hard refresh. |

## Sau khi xong

- Cập nhật `updatedAt` (và `pages` nếu có thêm/bớt trang) trong `site.config.json`.
- Nếu vừa thêm trang cần giới hạn quyền xem → nhắc chạy `access-control`.
