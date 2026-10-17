-- Run this migration in Supabase SQL Editor after migrations 001-003.
-- A delivery partner may see every active *unassigned* order. Orders claimed
-- by another rider remain private and disappear from the Available Orders tab.
create or replace function public.is_delivery_boy() returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='DELIVERY_BOY')
$$;

drop policy if exists "customers view their orders" on public.orders;
drop policy if exists "authorized users view orders" on public.orders;
create policy "customers view own orders" on public.orders for select using (customer_id=auth.uid());
create policy "admins view all orders" on public.orders for select using (public.is_admin());
create policy "delivery boys view available and own orders" on public.orders for select using (
  public.is_delivery_boy()
  and (delivery_boy_id is null or delivery_boy_id=auth.uid())
  and status not in ('DELIVERED','CANCELLED')
);

drop policy if exists "riders update assigned orders" on public.orders;
drop policy if exists "riders accept or update own orders" on public.orders;
create policy "delivery boys accept or update own orders" on public.orders for update using (
  public.is_delivery_boy()
  and (delivery_boy_id is null or delivery_boy_id=auth.uid())
) with check (
  public.is_delivery_boy() and delivery_boy_id=auth.uid()
);
