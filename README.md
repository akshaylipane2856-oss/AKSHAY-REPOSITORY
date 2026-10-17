# Sweet Home

Mobile-first Next.js storefront and operations dashboard for a local sweet shop.

## Start

1. Copy `.env.example` to `.env.local` and supply your Supabase project values.
2. For the simplified Customer + Delivery Boy build, run `supabase/RESET_AND_CREATE_SIMPLE.sql` in the Supabase SQL editor. Do not run the old numbered migrations afterward.
3. In Supabase Auth, enable Google and add `http://localhost:3000/auth/callback` (and your production URL) as redirect URLs.
4. `npm install && npm run dev`

The SQL migration creates tables, role-based RLS policies, user-profile trigger, and realtime publication. Staff roles must be assigned through the SQL editor or a trusted server-only admin action.
