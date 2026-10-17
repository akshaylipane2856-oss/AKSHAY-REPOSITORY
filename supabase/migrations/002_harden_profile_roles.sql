-- Run after 001_initial_schema.sql.
-- Role changes are staff-provisioning operations: execute them only in the SQL Editor
-- (or later through a trusted server-side admin RPC), never from a browser client.
revoke update on table public.profiles from anon, authenticated;
grant update (full_name, phone, avatar_url) on table public.profiles to authenticated;
