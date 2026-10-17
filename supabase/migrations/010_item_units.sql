-- Run this once in the Supabase SQL Editor before using kilogram quantities.
alter table public.order_items
  alter column quantity type numeric(8,2) using quantity::numeric;

alter table public.order_items
  add column if not exists unit text not null default 'KG'
  check (unit in ('KG', 'PIECE'));
