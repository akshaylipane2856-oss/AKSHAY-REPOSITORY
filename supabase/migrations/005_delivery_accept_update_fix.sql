-- Run this migration in Supabase SQL Editor after migrations 001-004.
-- Allows a delivery boy to atomically claim an unassigned order, then update it.
drop policy if exists "riders update assigned orders" on public.orders;
drop policy if exists "riders accept or update own orders" on public.orders;
drop policy if exists "delivery boys accept or update own orders" on public.orders;

create policy "delivery boys claim and update own orders"
on public.orders for update
using (
  public.is_delivery_boy()
  and (delivery_boy_id is null or delivery_boy_id = auth.uid())
)
with check (
  public.is_delivery_boy()
  and delivery_boy_id = auth.uid()
);
