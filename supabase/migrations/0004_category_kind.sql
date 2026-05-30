-- Income vs expense categories: a `kind` column on categories. Run in the
-- Supabase SQL editor after 0003. Existing rows default to 'expense'.

alter table public.categories
  add column if not exists kind text not null default 'expense';

alter table public.categories
  drop constraint if exists categories_kind_check;
alter table public.categories
  add constraint categories_kind_check check (kind in ('expense', 'income'));
