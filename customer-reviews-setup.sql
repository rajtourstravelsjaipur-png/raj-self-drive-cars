-- Run this script once in Supabase Dashboard > SQL Editor > New query.
-- Customer reviews are saved in Supabase, but remain hidden until an admin approves them.

create table if not exists public.customer_reviews (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null check (char_length(trim(customer_name)) between 1 and 80),
  rating integer not null check (rating between 1 and 5),
  feedback text not null check (char_length(trim(feedback)) between 1 and 1000),
  is_approved boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.customer_reviews enable row level security;

grant select, insert on public.customer_reviews to anon, authenticated;
grant update, delete on public.customer_reviews to authenticated;

drop policy if exists "Anyone can submit pending customer ratings" on public.customer_reviews;
create policy "Anyone can submit pending customer ratings"
on public.customer_reviews
for insert
to anon, authenticated
with check (
  char_length(trim(customer_name)) between 1 and 80
  and rating between 1 and 5
  and char_length(trim(feedback)) between 1 and 1000
  and is_approved = false
);

drop policy if exists "Public can read approved customer ratings" on public.customer_reviews;
create policy "Public can read approved customer ratings"
on public.customer_reviews
for select
to anon
using (is_approved = true);

drop policy if exists "Authenticated users can read approved ratings" on public.customer_reviews;
create policy "Authenticated users can read approved ratings"
on public.customer_reviews
for select
to authenticated
using (is_approved = true);

drop policy if exists "Site admins can read all customer ratings" on public.customer_reviews;
create policy "Site admins can read all customer ratings"
on public.customer_reviews
for select
to authenticated
using (public.is_site_admin() = true);

drop policy if exists "Site admins can update customer ratings" on public.customer_reviews;
create policy "Site admins can update customer ratings"
on public.customer_reviews
for update
to authenticated
using (public.is_site_admin() = true)
with check (public.is_site_admin() = true);

drop policy if exists "Site admins can delete customer ratings" on public.customer_reviews;
create policy "Site admins can delete customer ratings"
on public.customer_reviews
for delete
to authenticated
using (public.is_site_admin() = true);

notify pgrst, 'reload schema';
