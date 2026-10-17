-- Run this in Supabase SQL Editor after 006.
-- Creates a public bucket for sweet-product images, writable by admins only.
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

drop policy if exists "public reads product images" on storage.objects;
drop policy if exists "admins upload product images" on storage.objects;
drop policy if exists "admins update product images" on storage.objects;
drop policy if exists "admins delete product images" on storage.objects;

create policy "public reads product images" on storage.objects for select using (bucket_id = 'product-images');
create policy "admins upload product images" on storage.objects for insert with check (bucket_id = 'product-images' and public.is_admin());
create policy "admins update product images" on storage.objects for update using (bucket_id = 'product-images' and public.is_admin()) with check (bucket_id = 'product-images' and public.is_admin());
create policy "admins delete product images" on storage.objects for delete using (bucket_id = 'product-images' and public.is_admin());
