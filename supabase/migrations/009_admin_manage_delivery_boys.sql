-- Run after 006. Lets admins promote signed-in customers to delivery boys.
create policy "admins update profiles" on public.profiles for update
using (public.is_admin()) with check (public.is_admin());
grant update on public.profiles to authenticated;
