-- Sweet Home: run this migration in the Supabase SQL editor, then enable Google in Auth > Providers.
create type public.user_role as enum ('CUSTOMER','DELIVERY_BOY','ADMIN');
create type public.order_status as enum ('PLACED','CONFIRMED','PREPARING','READY_FOR_PICKUP','ASSIGNED','PICKED_UP','OUT_FOR_DELIVERY','DELIVERED','CANCELLED');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text, phone text, role public.user_role not null default 'CUSTOMER', avatar_url text,
  created_at timestamptz not null default now()
);
create table public.products (
  id uuid primary key default gen_random_uuid(), name text not null, description text, category text not null default 'Sweets',
  price numeric(10,2) not null check (price >= 0), image_url text, is_available boolean not null default true, created_at timestamptz not null default now()
);
create table public.addresses (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  line1 text not null, city text not null, pincode text not null, phone text, is_default boolean not null default false, created_at timestamptz not null default now()
);
create table public.orders (
  id uuid primary key default gen_random_uuid(), customer_id uuid not null references public.profiles(id), address_id uuid not null references public.addresses(id),
  delivery_boy_id uuid references public.profiles(id), status public.order_status not null default 'PLACED', total_amount numeric(10,2) not null default 0 check(total_amount >= 0), notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.order_items (
  id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade, product_id uuid references public.products(id),
  product_name text not null, unit_price numeric(10,2) not null, quantity integer not null check(quantity > 0), created_at timestamptz not null default now()
);
create table public.delivery_locations (
  id uuid primary key default gen_random_uuid(), delivery_boy_id uuid not null unique references public.profiles(id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null, latitude double precision not null, longitude double precision not null, updated_at timestamptz not null default now()
);
create index orders_customer_idx on public.orders(customer_id); create index orders_delivery_idx on public.orders(delivery_boy_id); create index order_items_order_idx on public.order_items(order_id);

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='ADMIN') $$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$ begin insert into public.profiles(id,full_name,avatar_url) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',new.raw_user_meta_data->>'name'),new.raw_user_meta_data->>'avatar_url'); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
create trigger orders_updated before update on public.orders for each row execute procedure public.set_updated_at();

alter table public.profiles enable row level security; alter table public.products enable row level security; alter table public.addresses enable row level security; alter table public.orders enable row level security; alter table public.order_items enable row level security; alter table public.delivery_locations enable row level security;
create policy "public reads available products" on public.products for select using (is_available or public.is_admin());
create policy "admins manage products" on public.products for all using (public.is_admin()) with check (public.is_admin());
create policy "users view own profile" on public.profiles for select using (id=auth.uid() or public.is_admin());
create policy "users update own profile" on public.profiles for update using (id=auth.uid() or public.is_admin()) with check (id=auth.uid() or public.is_admin());
create policy "own addresses" on public.addresses for all using (user_id=auth.uid() or public.is_admin()) with check (user_id=auth.uid() or public.is_admin());
create policy "customers view their orders" on public.orders for select using (customer_id=auth.uid() or delivery_boy_id=auth.uid() or public.is_admin());
create policy "customers create own orders" on public.orders for insert with check (customer_id=auth.uid() and exists(select 1 from public.addresses where id=address_id and user_id=auth.uid()));
create policy "admins manage orders" on public.orders for update using (public.is_admin()) with check (public.is_admin());
create policy "riders update assigned orders" on public.orders for update using (delivery_boy_id=auth.uid()) with check (delivery_boy_id=auth.uid());
create policy "visible order items" on public.order_items for select using (exists(select 1 from public.orders o where o.id=order_id and (o.customer_id=auth.uid() or o.delivery_boy_id=auth.uid() or public.is_admin())));
create policy "customer adds own items" on public.order_items for insert with check (exists(select 1 from public.orders o where o.id=order_id and o.customer_id=auth.uid()));
create policy "admins manage items" on public.order_items for all using (public.is_admin()) with check(public.is_admin());
create policy "riders submit location" on public.delivery_locations for insert with check(delivery_boy_id=auth.uid());
create policy "riders update location" on public.delivery_locations for update using(delivery_boy_id=auth.uid()) with check(delivery_boy_id=auth.uid());
create policy "location visible to involved users" on public.delivery_locations for select using (delivery_boy_id=auth.uid() or public.is_admin() or exists(select 1 from public.orders o where o.id=order_id and o.customer_id=auth.uid()));
alter publication supabase_realtime add table public.orders, public.delivery_locations;

-- Provision staff only from the SQL editor / trusted server context:
-- update public.profiles set role='ADMIN' where id='...';
-- update public.profiles set role='DELIVERY_BOY' where id='...';
