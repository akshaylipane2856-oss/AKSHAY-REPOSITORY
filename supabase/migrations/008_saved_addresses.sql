-- Run this after RESET_AND_CREATE_SIMPLE.sql.
-- Separates one-time delivery addresses from customer-saved reusable addresses.
alter table public.addresses add column if not exists save_for_later boolean not null default false;
notify pgrst, 'reload schema';
