-- SWEET HOME SIMPLE RESET
-- Run this ONE script in Supabase SQL Editor. It deletes the existing app data
-- and replaces the old multi-role setup with Customer + Delivery Boy only.

drop table if exists public.delivery_locations cascade;
drop table if exists public.order_items cascade;
drop table if exists public.orders cascade;
drop table if exists public.addresses cascade;
drop table if exists public.products cascade;
drop table if exists public.profiles cascade;
drop function if exists public.is_admin() cascade;
drop function if exists public.is_delivery_boy() cascade;
drop function if exists public.handle_new_user() cascade;
drop function if exists public.set_updated_at() cascade;
drop type if exists public.user_role cascade;
drop type if exists public.order_status cascade;

create type public.user_role as enum ('CUSTOMER','DELIVERY_BOY');
create type public.order_status as enum ('PLACED','ACCEPTED','PREPARING','READY_FOR_PICKUP','OUT_FOR_DELIVERY','DELIVERED','CANCELLED');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role public.user_role not null default 'CUSTOMER',
  created_at timestamptz not null default now()
);
create table public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null, description text, category text not null default 'Sweets',
  price numeric(10,2) not null check(price >= 0), image_url text,
  is_available boolean not null default true, created_at timestamptz not null default now()
);
create table public.addresses (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  line1 text not null, city text not null, pincode text not null, phone text,
  created_at timestamptz not null default now()
);
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id),
  address_id uuid not null references public.addresses(id),
  delivery_boy_id uuid references public.profiles(id),
  status public.order_status not null default 'PLACED',
  total_amount numeric(10,2) not null default 0 check(total_amount >= 0),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.order_items (
  id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id), product_name text not null,
  unit_price numeric(10,2) not null, quantity numeric(8,2) not null check(quantity > 0),
  unit text not null default 'KG' check (unit in ('KG', 'PIECE'))
);
create table public.delivery_locations (
  id uuid primary key default gen_random_uuid(), delivery_boy_id uuid not null unique references public.profiles(id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null, latitude double precision not null, longitude double precision not null,
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',new.raw_user_meta_data->>'name'));
  return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
create or replace function public.is_delivery_boy() returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='DELIVERY_BOY')
$$;
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
create trigger orders_updated before update on public.orders for each row execute procedure public.set_updated_at();

-- Recreate profiles for Google users who signed in before this reset.
insert into public.profiles(id,full_name)
select id,coalesce(raw_user_meta_data->>'full_name',raw_user_meta_data->>'name') from auth.users
on conflict (id) do nothing;

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.delivery_locations enable row level security;

grant usage on schema public to anon, authenticated;
grant select on public.products to anon, authenticated;
grant select on public.profiles to authenticated;
grant select, insert on public.addresses to authenticated;
grant select, insert, update on public.orders to authenticated;
grant select, insert on public.order_items to authenticated;
grant select, insert, update, delete on public.delivery_locations to authenticated;

create policy "public reads products" on public.products for select using(is_available);
create policy "users read own profile" on public.profiles for select using(id=auth.uid() or public.is_delivery_boy());
create policy "customers read own addresses" on public.addresses for select using(user_id=auth.uid() or public.is_delivery_boy());
create policy "customers add addresses" on public.addresses for insert with check(user_id=auth.uid());
create policy "customers read own orders" on public.orders for select using(customer_id=auth.uid());
create policy "delivery boy reads all orders" on public.orders for select using(public.is_delivery_boy());
create policy "customers place own orders" on public.orders for insert with check(customer_id=auth.uid() and exists(select 1 from public.addresses where id=address_id and user_id=auth.uid()));
create policy "delivery boy accepts and updates orders" on public.orders for update using(public.is_delivery_boy() and (delivery_boy_id is null or delivery_boy_id=auth.uid())) with check(public.is_delivery_boy() and delivery_boy_id=auth.uid());
create policy "customers read own order items" on public.order_items for select using(exists(select 1 from public.orders where id=order_id and customer_id=auth.uid()));
create policy "delivery boy reads order items" on public.order_items for select using(public.is_delivery_boy());
create policy "customers add own order items" on public.order_items for insert with check(exists(select 1 from public.orders where id=order_id and customer_id=auth.uid()));
create policy "delivery boy updates location" on public.delivery_locations for all using(delivery_boy_id=auth.uid() and public.is_delivery_boy()) with check(delivery_boy_id=auth.uid() and public.is_delivery_boy());
alter publication supabase_realtime add table public.orders, public.delivery_locations;

-- After running, set ONE existing Google user as the delivery boy:
-- update public.profiles set role='DELIVERY_BOY' where id='PASTE_DELIVERY_USER_UUID';
