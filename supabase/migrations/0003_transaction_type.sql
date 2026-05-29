-- Income vs expense: a `type` column on expenses. Run in the Supabase SQL
-- editor after 0002. Existing rows default to 'expense'.

alter table public.expenses
  add column if not exists type text not null default 'expense';

-- Guard against unexpected values coming from clients.
alter table public.expenses
  drop constraint if exists expenses_type_check;
alter table public.expenses
  add constraint expenses_type_check check (type in ('expense', 'income'));
