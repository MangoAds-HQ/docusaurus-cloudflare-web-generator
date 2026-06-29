#!/usr/bin/env node
// sync-access.mjs — đồng bộ Cloudflare Access theo access-control/access.csv.
//
// Đọc:  .env (CF_API_TOKEN, CF_ACCOUNT_ID), site.config.json (domain, pages),
//       access-control/access.csv (email -> pages).
// Làm: với mỗi trang có người được cấp quyền -> tạo/cập nhật Access app + policy
//      (allow, include đúng danh sách email). CSV là nguồn chân lý: PUT toàn bộ
//      danh sách nên ai bị xóa khỏi CSV cũng biến mất khỏi policy (sync, không chỉ thêm).
//
// Chạy ở GỐC dự án:
//   node .codex/skills/access-control/scripts/sync-access.mjs            # áp dụng
//   node .codex/skills/access-control/scripts/sync-access.mjs --dry-run  # chỉ xem, không đổi gì
//   node .codex/skills/access-control/scripts/sync-access.mjs --prune    # đồng thời XÓA app của trang không còn trong CSV
//
// Tùy chọn khác: --csv <path> --config <path> --env <path>
// Yêu cầu Node >= 18 (global fetch).

import fs from "node:fs";

// ---------- args ----------
const argv = process.argv.slice(2);
const opt = { dryRun: false, prune: false, csv: "access-control/access.csv", config: "site.config.json", env: ".env" };
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === "--dry-run") opt.dryRun = true;
  else if (a === "--prune") opt.prune = true;
  else if (a === "--csv") opt.csv = argv[++i];
  else if (a === "--config") opt.config = argv[++i];
  else if (a === "--env") opt.env = argv[++i];
  else { console.error(`Tham số không hiểu: ${a}`); process.exit(2); }
}

const die = (msg) => { console.error("✗ " + msg); process.exit(1); };

// ---------- load .env ----------
function parseEnv(path) {
  const out = {};
  if (!fs.existsSync(path)) return out;
  for (let line of fs.readFileSync(path, "utf8").split("\n")) {
    line = line.trim();
    if (!line || line.startsWith("#")) continue;
    line = line.replace(/^export\s+/, "");
    const eq = line.indexOf("=");
    if (eq === -1) continue;
    const k = line.slice(0, eq).trim();
    let v = line.slice(eq + 1).trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
    out[k] = v;
  }
  return out;
}
const envFile = parseEnv(opt.env);
const TOKEN = process.env.CF_API_TOKEN || envFile.CF_API_TOKEN;
const ACCOUNT = process.env.CF_ACCOUNT_ID || envFile.CF_ACCOUNT_ID;
if (!TOKEN) die(`Thiếu CF_API_TOKEN (trong ${opt.env} hoặc biến môi trường).`);
if (!ACCOUNT) die(`Thiếu CF_ACCOUNT_ID (trong ${opt.env} hoặc biến môi trường).`);

// ---------- load site.config.json ----------
if (!fs.existsSync(opt.config)) die(`Không thấy ${opt.config}. Hãy chạy setup-project / create-web trước.`);
const cfg = JSON.parse(fs.readFileSync(opt.config, "utf8"));
const DOMAIN = cfg.useCustomDomain && cfg.customDomain ? cfg.customDomain : cfg.domain;
if (!DOMAIN) die("site.config.json thiếu 'domain'.");
const validSlugs = new Set((cfg.pages || []).map((p) => p.slug).filter(Boolean));
if (validSlugs.size === 0) console.warn("⚠ site.config.json chưa có trang nào trong 'pages' — sẽ không validate được slug.");

// ---------- parse CSV ----------
if (!fs.existsSync(opt.csv)) die(`Không thấy ${opt.csv}. Chạy init-access-control.sh để tạo mẫu rồi điền.`);
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const slugToEmails = new Map(); // slug -> Set(email)
const errors = [];
const merged = [];
{
  const lines = fs.readFileSync(opt.csv, "utf8").split("\n").map((l) => l.trim());
  let start = 0;
  if (lines[0] && lines[0].toLowerCase().replace(/\s/g, "").startsWith("email,")) start = 1;
  const seenEmails = new Set();
  for (let i = start; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;
    const comma = line.indexOf(",");
    if (comma === -1) { errors.push(`Dòng ${i + 1}: thiếu dấu phẩy ngăn email và pages: "${line}"`); continue; }
    const email = line.slice(0, comma).trim();
    const pagesRaw = line.slice(comma + 1).trim();
    if (!EMAIL_RE.test(email)) { errors.push(`Dòng ${i + 1}: email sai định dạng: "${email}"`); continue; }
    if (seenEmails.has(email.toLowerCase())) merged.push(email);
    seenEmails.add(email.toLowerCase());
    const slugs = pagesRaw.split(";").map((s) => s.trim()).filter(Boolean);
    if (slugs.length === 0) { errors.push(`Dòng ${i + 1}: email ${email} không có trang nào ở cột pages.`); continue; }
    for (const slug of slugs) {
      if (validSlugs.size > 0 && !validSlugs.has(slug)) {
        errors.push(`Dòng ${i + 1}: trang "${slug}" không có trên web. Các trang hiện có: ${[...validSlugs].join(", ") || "(chưa có)"}`);
        continue;
      }
      if (!slugToEmails.has(slug)) slugToEmails.set(slug, new Set());
      slugToEmails.get(slug).add(email);
    }
  }
}
if (errors.length) {
  console.error("✗ CSV có lỗi, sửa rồi chạy lại:");
  for (const e of errors) console.error("  - " + e);
  process.exit(1);
}
if (merged.length) console.warn(`ℹ Đã gộp email xuất hiện nhiều dòng (union trang): ${[...new Set(merged)].join(", ")}`);
if (slugToEmails.size === 0) die("CSV không có dòng hợp lệ nào.");

// seat warning (Free Zero Trust ~ 50 user)
const uniqueEmails = new Set();
for (const set of slugToEmails.values()) for (const e of set) uniqueEmails.add(e.toLowerCase());
if (uniqueEmails.size > 50) console.warn(`⚠ CSV có ${uniqueEmails.size} email — bản Free Zero Trust giới hạn ~50 seat. Có thể vượt hạn mức.`);

// ---------- Cloudflare API helpers ----------
const BASE = `https://api.cloudflare.com/client/v4/accounts/${ACCOUNT}`;
async function cf(method, path, body) {
  const res = await fetch(BASE + path, {
    method,
    headers: { Authorization: `Bearer ${TOKEN}`, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  let json;
  try { json = await res.json(); } catch { json = {}; }
  if (!res.ok || json.success === false) {
    const errs = (json.errors || []).map((e) => `${e.code} ${e.message}`).join("; ") || res.statusText;
    throw new Error(`${method} ${path} -> ${res.status}: ${errs}`);
  }
  return json.result;
}

// app.domain dạng "<domain>/<slug>*". Lấy slug từ một app domain để so khớp.
const appDomainFor = (slug) => `${DOMAIN}/${slug}*`;
function slugFromAppDomain(d) {
  if (!d || !d.startsWith(DOMAIN + "/")) return null;
  let rest = d.slice(DOMAIN.length + 1);
  if (rest.endsWith("*")) rest = rest.slice(0, -1);
  if (rest.endsWith("/")) rest = rest.slice(0, -1);
  return rest || null;
}
const includeFor = (emails) => [...emails].map((email) => ({ email: { email } }));

// ---------- main ----------
const tag = opt.dryRun ? "[DRY-RUN] " : "";
console.log(`==> ${tag}Đồng bộ Access cho ${DOMAIN} (account …${ACCOUNT.slice(-4)})`);

// 1) Đảm bảo có IdP one-time PIN (OTP). Best-effort.
try {
  const idps = (await cf("GET", "/access/identity_providers")) || [];
  if (!idps.some((p) => p.type === "onetimepin")) {
    if (opt.dryRun) console.log("   [DRY-RUN] sẽ tạo IdP One-time PIN (OTP).");
    else { await cf("POST", "/access/identity_providers", { name: "OTP", type: "onetimepin" }); console.log("   ✓ đã bật IdP One-time PIN (OTP)."); }
  } else console.log("   ✓ OTP đã sẵn sàng.");
} catch (e) { console.warn("   ⚠ không kiểm tra/tạo được IdP OTP (có thể đã có sẵn): " + e.message); }

try {
// 2) Liệt kê app hiện có thuộc site này.
const allApps = (await cf("GET", "/access/apps?per_page=1000")) || [];
const siteApps = new Map(); // slug -> app
for (const app of allApps) {
  const slug = slugFromAppDomain(app.domain);
  if (slug) siteApps.set(slug, app);
}

// 3) Upsert từng trang trong CSV.
const summary = [];
for (const [slug, emailsSet] of slugToEmails) {
  const emails = [...emailsSet];
  let app = siteApps.get(slug);
  let action;
  if (!app) {
    if (opt.dryRun) { summary.push({ slug, n: emails.length, action: "sẽ TẠO app + policy" }); continue; }
    app = await cf("POST", "/access/apps", {
      name: `${slug} - ${cfg.projectName || DOMAIN}`,
      type: "self_hosted",
      domain: appDomainFor(slug),
      session_duration: "24h",
    });
    action = "tạo app";
  } else {
    action = "cập nhật";
  }

  // policy: tìm policy allow hiện có, PUT đè include; chưa có thì POST.
  const policies = (await cf("GET", `/access/apps/${app.id}/policies`)) || [];
  const existing = policies.find((p) => p.decision === "allow") || policies[0];
  const policyBody = { name: `allow-${slug}`, decision: "allow", include: includeFor(emailsSet) };
  if (opt.dryRun) {
    summary.push({ slug, n: emails.length, action: existing ? "sẽ cập nhật policy" : "sẽ tạo policy" });
    continue;
  }
  if (existing) await cf("PUT", `/access/apps/${app.id}/policies/${existing.id}`, policyBody);
  else await cf("POST", `/access/apps/${app.id}/policies`, policyBody);
  summary.push({ slug, n: emails.length, action: `${action} + đặt ${emails.length} email` });
}

// 4) Dọn (prune) app của trang không còn trong CSV.
const orphans = [...siteApps.keys()].filter((slug) => !slugToEmails.has(slug));
const pruned = [];
for (const slug of orphans) {
  const app = siteApps.get(slug);
  if (opt.prune && !opt.dryRun) {
    await cf("DELETE", `/access/apps/${app.id}`);
    pruned.push(slug);
  }
}

// ---------- report ----------
console.log("\n--- Kết quả ---");
for (const s of summary) console.log(`  /${s.slug}: ${s.n} email — ${s.action}`);
if (orphans.length) {
  if (opt.prune) {
    if (!opt.dryRun) console.log(`  Đã XÓA app (trang không còn trong CSV → trở lại public): ${pruned.join(", ")}`);
    else console.log(`  [DRY-RUN] sẽ XÓA app: ${orphans.join(", ")}`);
  } else {
    console.log(`  ⚠ Các trang sau có Access app nhưng KHÔNG còn trong CSV: ${orphans.join(", ")}`);
    console.log(`     Muốn gỡ quyền (cho public xem lại) thì xác nhận với người dùng rồi chạy lại với --prune.`);
  }
}
console.log(opt.dryRun ? "\n[DRY-RUN] Chưa thay đổi gì trên Cloudflare." : "\n✓ Đồng bộ xong.");
} catch (e) {
  console.error("\n✗ Lỗi khi gọi Cloudflare API: " + e.message);
  console.error("  Kiểm tra: token trong .env đủ quyền (Access: Apps and Policies + Organizations/IdP/Groups: Edit),");
  console.error("  CF_ACCOUNT_ID đúng, và tài khoản đã onboard Zero Trust (xem setup-project/references/zero-trust-onboarding.md).");
  process.exit(1);
}
