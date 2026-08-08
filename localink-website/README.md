# Vocal for Sanatan — Marketing Website

Play Store–ready marketing site for **Vocal for Sanatan** (`com.vocalforsanatan.app`).

## Develop locally

```bash
cd localink-website
npm install
npm run dev
```

Open http://localhost:3000

## Deploy to Vercel + custom domain

Your site lives in the monorepo folder `localink-website/`. Domain: **vocalforsanatan.com**.

### 1) Push code to GitHub

Commit and push at least the `localink-website` folder to:

`https://github.com/Sankeerth2005/Internship-Project`

Vercel builds from Git — uncommitted local files will not deploy.

### 2) Create / update the Vercel project

1. Go to [vercel.com](https://vercel.com) → **Add New…** → **Project**
2. Import **`Sankeerth2005/Internship-Project`**
3. Configure:
   - **Framework Preset:** Next.js
   - **Root Directory:** `localink-website` ← important
   - **Build Command:** `npm run build` (default)
   - **Output:** leave default (Next.js)
4. Click **Deploy**

If a project already exists for `vocalforsanatan.com`, open it → **Settings → General → Root Directory** → set to `localink-website` → Redeploy.

### 3) Connect your domain (GoDaddy)

In Vercel:

1. Project → **Settings → Domains**
2. Add:
   - `vocalforsanatan.com`
   - `www.vocalforsanatan.com`
3. Vercel will show the DNS records to use.

In GoDaddy (DNS for `vocalforsanatan.com`):

| Type | Name | Value | Notes |
|------|------|--------|--------|
| **A** | `@` | `76.76.21.21` | Apex / root domain |
| **CNAME** | `www` | `cname.vercel-dns.com` | www subdomain |

Remove any old A/CNAME records that point elsewhere (old hosting, previous Vercel project, parking pages).

DNS usually updates in a few minutes to a few hours. Vercel will show **Valid** when SSL is ready.

### 4) Verify

Open:

- https://vocalforsanatan.com
- https://vocalforsanatan.com/privacy
- https://vocalforsanatan.com/support
- https://vocalforsanatan.com/delete-account

### 5) Google Play Console URLs

| Field | URL |
|--------|-----|
| Privacy policy | `https://vocalforsanatan.com/privacy` |
| Support | `https://vocalforsanatan.com/support` |
| Account deletion | `https://vocalforsanatan.com/delete-account` |

## Optional: deploy from CLI

```bash
cd localink-website
npx vercel login
npx vercel          # preview
npx vercel --prod   # production
```

When prompted, link to the existing Git project and set root to `localink-website`.

## Pages

| URL | Purpose |
|-----|---------|
| `/` | Landing |
| `/privacy` | Privacy Policy (Play required) |
| `/terms` | Terms of Service |
| `/delete-account` | Account deletion (Play required) |
| `/support` | Support |
| `/download` | Store links |
| `/business` `/about` `/features` `/faq` `/contact` | Product & help |
