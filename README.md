# WorldCon

**Manufacturing starts with what the buyer needs.** WorldCon is a responsive buyer-first B2B manufacturing marketplace. Companies publish detailed sourcing requirements; manufacturers discover them, provide quotations and lead times, and message buyers directly. Buyers choose their supplier and award the sourcing request.

## Features

- Responsive marketing homepage, category-based searchable sourcing board, request detail pages
- Email/password authentication with Supabase Auth; buyer and manufacturer profiles
- Company profiles and production capability listings
- Buyer request creation with categories, specifications, quantities, budgets and deadlines
- Manufacturer proposals with USD quotes, lead times and a short production plan
- Secure one-off award action that accepts one offer and declines competing offers atomically
- Buyer and supplier dashboard views, private conversation threads, profile management
- Row-level database permissions with organization ownership enforcement
- Explicitly labelled sample data when no Supabase project has been connected

## Setup

Requirements: Node.js 20+ and a Supabase project. The app is client-side React and can be hosted on Vercel, Netlify, Cloudflare Pages or other SPA-capable hosts.

1. Create a free Supabase project and open **SQL Editor**.
2. Run `supabase/migrations/001_initial.sql` in the SQL Editor. This installs the database, trigger, secure RPC and row-level security policies.
3. In Supabase Authentication, configure **URL Configuration** with your production website URL and any localhost URL used for development. For development, you may need to adjust email confirmation behavior. Configure outbound email delivery for production.
4. Copy `.env.example` to `.env`, then populate your project URL and **publishable/anon** key. Never put the `service_role` secret key in the browser.
5. Run `npm install` followed by `npm run dev`. To compile, run `npm run build`.
6. Deploy with build command `npm run build`, output directory `dist`, and set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` as build-time environment variables. Configure SPA fallback so `/requests/...` works on direct visits.

### Deployment example: Cloudflare Pages

Framework: Vite. Build: `npm run build`. Output: `dist`. Configure the two `VITE_` environment variables under project settings. The `public/_redirects` file supports compatible hosts; Cloudflare Pages also automatically treats projects without a top-level 404.html as SPA for navigation.

### Roles and company ownership

Each user owns one company record in this first release. The first authenticated save of the company profile creates the company. Each user is either a `buyer` or a `manufacturer` for the purpose of new requests/offers. Existing data remains linked to the company if the user updates their role; public-launch policy should restrict role switching or introduce independent company verification. Buyers cannot respond to their own requests. Manufacturers can submit one offer per request. Buyers can see offers on their requests, and only companies participating in the offer can see its messages. Awarding an offer via the `accept_offer` SQL function changes the request and other proposals atomically.

### Example workflows

- Buyer: Sign up as buyer → complete business profile → Post request → review proposals on the request detail → message manufacturer → accept offer.
- Manufacturer: Sign up as manufacturer → complete business profile → Browse requests → open a request → submit price, lead time and capabilities → message buyer.

### Limitations and launch checklist

This is a **functional MVP codebase** once configured; it is not yet a production-audited marketplace or live commercial service. Before opening registration to the public:

- Connect and deploy a real Supabase project, confirm end-to-end registration, posting, bidding, award, and message privacy using separate buyer/manufacturer accounts.
- Add rate limiting, CAPTCHA, user/report moderation and abuse monitoring to prevent spam and fraud.
- Verify company identities and supplier certifications and implement sanctions/export-control and prohibited-product screening where relevant.
- Add file upload with private signed access for specifications, drawings and NDAs. Do not upload confidential documents to public storage or place them in public request descriptions.
- Add notifications and transactional email via a configured sending provider; current messages require returning to the app to see updates.
- Implement offer cancellation and closed-request semantics as needed, audit logs, and more granular team/company permissions.
- Have counsel review privacy/terms, liability, data retention, applicable local laws and site operator details. Replace in-app placeholder legal language.
- Add pagination for high listing volumes, accessibility testing, automated end-to-end tests, analytics and monitoring.

WorldCon does not process payments or manage production orders. Negotiation, contracting, inspection and fulfillment occur between buyers and manufacturers.

## Tech

React 18, Vite 6, React Router, Lucide icons, Supabase Auth + Postgres with row level security. No paid dependencies required for a small pilot, subject to provider free-tier limits.
