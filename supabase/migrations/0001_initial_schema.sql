-- Flo backend schema: categories, expenses, budgets.
-- Mirrors the local Drift tables. The client generates UUID ids, so sync is an
-- idempotent upsert. `updated_at` is maintained server-side (authoritative for
-- last-write-wins). `sync_status` is a local-only concept and is NOT stored here.
-- Soft deletes use `deleted_at` so tombstones propagate during sync.

-- Keeps updated_at current on every UPDATE (server is the source of truth).
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ───────────────────────── categories ─────────────────────────
create table if not exists public.categories (
  id          uuid primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  name        text not null,
  icon        text not null,
  color_hex   text not null,
  is_default  boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);
create index if not exists categories_user_updated_idx
  on public.categories (user_id, updated_at);

-- ───────────────────────── expenses ─────────────────────────
-- No FK on category_id: offline clients may create an expense before its
-- category has synced. Integrity is enforced in the app.
create table if not exists public.expenses (
  id            uuid primary key,
  user_id       uuid not null references auth.users (id) on delete cascade,
  amount_cents  bigint not null,
  category_id   uuid not null,
  merchant      text,
  note          text,
  date          timestamptz not null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);
create index if not exists expenses_user_updated_idx
  on public.expenses (user_id, updated_at);
create index if not exists expenses_user_date_idx
  on public.expenses (user_id, date);

-- ───────────────────────── budgets ─────────────────────────
create table if not exists public.budgets (
  id           uuid primary key,
  user_id      uuid not null references auth.users (id) on delete cascade,
  category_id  uuid not null,
  limit_cents  bigint not null,
  period       text not null default 'monthly' check (period in ('monthly', 'weekly')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz
);
create index if not exists budgets_user_updated_idx
  on public.budgets (user_id, updated_at);

-- ───────────────────────── updated_at triggers ─────────────────────────
drop trigger if exists categories_set_updated_at on public.categories;
create trigger categories_set_updated_at
  before update on public.categories
  for each row execute function public.set_updated_at();

drop trigger if exists expenses_set_updated_at on public.expenses;
create trigger expenses_set_updated_at
  before update on public.expenses
  for each row execute function public.set_updated_at();

drop trigger if exists budgets_set_updated_at on public.budgets;
create trigger budgets_set_updated_at
  before update on public.budgets
  for each row execute function public.set_updated_at();

-- ───────────────────────── Row Level Security ─────────────────────────
alter table public.categories enable row level security;
alter table public.expenses   enable row level security;
alter table public.budgets    enable row level security;

-- A user may read/write only their own rows.
drop policy if exists categories_owner on public.categories;
create policy categories_owner on public.categories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists expenses_owner on public.expenses;
create policy expenses_owner on public.expenses
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists budgets_owner on public.budgets;
create policy budgets_owner on public.budgets
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
