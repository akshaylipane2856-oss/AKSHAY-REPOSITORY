-- Run this after RESET_AND_CREATE_SIMPLE.sql to enable the admin dashboard.
alter type public.user_role add value if not exists 'ADMIN';

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role::text='ADMIN')
$$;

drop policy if exists "users read own profile" on public.profiles;
create policy "users and staff read profiles" on public.profiles for select using (
  id=auth.uid() or public.is_delivery_boy() or public.is_admin()
);
create policy "admins manage products" on public.products for all using (public.is_admin()) with check (public.is_admin());
create policy "admins read addresses" on public.addresses for select using (public.is_admin());
create policy "admins read orders" on public.orders for select using (public.is_admin());
create policy "admins read order items" on public.order_items for select using (public.is_admin());
create policy "admins read delivery locations" on public.delivery_locations for select using (public.is_admin());
grant select, insert, update, delete on public.products to authenticated;

-- Promote a signed-in Google user to admin:
-- update public.profiles set role='ADMIN' where id='PASTE_ADMIN_USER_UUID';
