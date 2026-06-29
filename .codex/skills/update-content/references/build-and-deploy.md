# Build & redeploy

Web đã tồn tại từ `create-web`. Đây chỉ là rebuild + đẩy bản mới. Không tạo lại project.

## Cách 1 — script deploy.sh (khuyến nghị)

Chạy ở **gốc dự án** (nạp `.env`, build lại, deploy; project đã có nên bỏ qua bước tạo):

```bash
bash .codex/skills/update-content/scripts/deploy.sh
```

Tùy chọn: `--no-build` nếu vừa `npm run build` xong và không muốn build lại.

## Cách 2 — wrangler thủ công

```bash
set -a; . ./.env; set +a       # đứng ở gốc dự án; nếu đang trong thư mục project thì . ../.env
export CLOUDFLARE_API_TOKEN=$CF_API_TOKEN
export CLOUDFLARE_ACCOUNT_ID=$CF_ACCOUNT_ID

cd <projectName>
npm run build      # output ra ./build, sửa trước nếu lỗi — đừng deploy bản hỏng
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
