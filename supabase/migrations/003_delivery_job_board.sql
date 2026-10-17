-- Run after 001 and 002. Delivery partners may discover unassigned jobs,
-- but only see a customer's address after they have accepted the job.
create or replace function public.is_delivery_boy() returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='DELIVERY_BOY')
$$;

drop policy if exists "customers view their orders" on public.orders;
create policy "authorized users view orders" on public.orders for select using (
  customer_id=auth.uid()
  or public.is_admin()
  or (public.is_delivery_boy() and (delivery_boy_id is null or delivery_boy_id=auth.uid()))
);

drop policy if exists "riders update assigned orders" on public.orders;
create policy "riders accept or update own orders" on public.orders for update using (
  public.is_delivery_boy() and (delivery_boy_id is null or delivery_boy_id=auth.uid())
) with check (
  public.is_delivery_boy() and delivery_boy_id=auth.uid()
);

drop policy if exists "own addresses" on public.addresses;
create policy "authorized users view addresses" on public.addresses for select using (
  user_id=auth.uid() or public.is_admin() or exists(
    select 1 from public.orders o where o.address_id=id and o.delivery_boy_id=auth.uid() and public.is_delivery_boy()
  )
);
create policy "users manage own addresses" on public.addresses for insert with check (user_id=auth.uid() or public.is_admin());
create policy "users update own addresses" on public.addresses for update using (user_id=auth.uid() or public.is_admin()) with check (user_id=auth.uid() or public.is_admin());
create policy "users delete own addresses" on public.addresses for delete using (user_id=auth.uid() or public.is_admin());
