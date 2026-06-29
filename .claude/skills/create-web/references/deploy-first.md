# Deploy lần đầu lên Cloudflare Pages

Phần này gọi Cloudflare. Đường mặc định: **direct upload qua wrangler** (không cần GitHub). Dưới đây là lệnh sẵn dùng + phương án API thuần nếu cần script hóa sau.

## Chuẩn bị biến môi trường

```bash
source .cloudflare-secret
export CLOUDFLARE_API_TOKEN=$CF_API_TOKEN
export CLOUDFLARE_ACCOUNT_ID=$CF_ACCOUNT_ID
```

## Cách 1 — wrangler (khuyến nghị, đơn giản nhất)

Từ trong thư mục project (đã `npm run build`, output ở `build/`):

```bash
# Tạo project Pages (chỉ cần lần đầu). production branch đặt là "main".
npx wrangler pages project create <projectName> --production-branch main

# Deploy thư mục build
npx wrangler pages deploy build --project-name <projectName> --branch main
```

Lệnh deploy in ra URL `https://<projectName>.pages.dev`. Đưa cho người dùng.

> Nếu `project create` báo project đã tồn tại → bỏ qua bước create, chạy thẳng deploy.

## Cách 2 — REST API thuần (để agent script hóa sau)

> 🔧 **Phần này để agent tự dựng script sau theo yêu cầu của chủ dự án.** Direct upload qua API gồm nhiều bước (tạo project, lấy upload token, hash & upload từng file, tạo deployment). Wrangler đã gói trọn việc này nên với non-tech dùng wrangler là đủ. Chỉ chuyển sang API thuần nếu cần nhúng vào pipeline không có Node.

Tham chiếu endpoint:
- Tạo project: `POST https://api.cloudflare.com/client/v4/accounts/{account_id}/pages/projects`
  body tối thiểu: `{ "name": "<projectName>", "production_branch": "main" }`
- Liệt kê deployment: `GET .../pages/projects/{project_name}/deployments`
- Trigger / tạo deployment: `POST .../pages/projects/{project_name}/deployments`

Header: `Authorization: Bearer $CF_API_TOKEN`.

Logic direct-upload (nếu tự code): tạo project → `GET /pages/projects/{name}/upload-token` → tính hash từng file → check missing → upload blob còn thiếu → `POST /deployments` với manifest. Khuyến nghị: đừng tự viết, gọi `wrangler pages deploy` cho chắc.

## Sau khi deploy

- Cập nhật `site.config.json`: `status.webCreated=true`, `status.firstDeploy=true`, `domain="<projectName>.pages.dev"` (nếu chưa set).
- Bảo người dùng mở URL kiểm tra. Lần đầu có thể mất 1-2 phút để lan truyền.

## Tùy chọn: dùng GitHub thay vì direct upload

Chỉ làm nếu người dùng chủ động muốn (mỗi `git push` tự build). Cần: người dùng có tài khoản GitHub + repo, rồi connect trong dashboard Pages (Workers & Pages → Create → Pages → Connect to Git). Với non-tech, direct upload ít ma sát hơn — mặc định dùng nó.

## Lỗi thường gặp

- `Authentication error` / 403 → token thiếu quyền **Cloudflare Pages: Edit** (xem api-token-scopes.md).
- Deploy xong mở web trắng / 404 asset → `baseUrl` trong `docusaurus.config.js` phải là `/`.
- Quá nhiều project tạo trong thời gian ngắn bị chặn tạm → đây là throttle chống abuse của Cloudflare, chờ hoặc liên hệ support; khi onboard nhiều khách nên giãn nhịp tạo project.
