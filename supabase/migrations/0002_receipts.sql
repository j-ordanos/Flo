-- Receipts: a column on expenses + a private Storage bucket scoped per user.
-- Run this in the Supabase SQL editor after 0001.

alter table public.expenses add column if not exists receipt_path text;

-- Private bucket for receipt images.
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do nothing;

-- Access is limited to each user's own folder: receipts/<auth.uid()>/...
drop policy if exists receipts_owner_select on storage.objects;
create policy receipts_owner_select on storage.objects
  for select using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists receipts_owner_insert on storage.objects;
create policy receipts_owner_insert on storage.objects
  for insert with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists receipts_owner_update on storage.objects;
create policy receipts_owner_update on storage.objects
  for update using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists receipts_owner_delete on storage.objects;
create policy receipts_owner_delete on storage.objects
  for delete using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
