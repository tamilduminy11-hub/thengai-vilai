-- Public coconut/copra rates. Anyone may read; only the service role (the fetch job) writes.

create table public.series (
  id          text primary key,            -- e.g. cdb.milling_copra.kangayam
  source      text not null,               -- cdb | agmarknet
  product     text not null,
  product_en  text not null,
  product_ta  text not null,
  market      text not null,
  market_en   text not null,
  market_ta   text not null
);

create table public.rates (
  series_id   text not null references public.series(id) on delete cascade,
  day         date not null,
  per_kg      numeric(12,2) not null check (per_kg > 0),
  raw         numeric(14,2) not null,
  raw_unit    text not null,               -- quintal | tonne
  first_seen  timestamptz not null,        -- when our fetcher first saw this value
  updated     timestamptz not null,        -- last time the source revised it
  primary key (series_id, day)
);
create index rates_day_idx on public.rates (day desc);

-- Fetch-run bookkeeping (last checked time shown in the app).
create table public.meta (
  key    text primary key,
  value  jsonb not null
);

-- Latest value per series with the change from the previous reported day.
create view public.latest_rates with (security_invoker = true) as
select s.*, r.day, r.per_kg, r.first_seen,
       r.per_kg - p.per_kg as change_per_kg,
       p.day as prev_day
from public.series s
join lateral (
  select * from public.rates x where x.series_id = s.id order by x.day desc limit 1
) r on true
left join lateral (
  select * from public.rates y where y.series_id = s.id and y.day < r.day order by y.day desc limit 1
) p on true;

alter table public.series enable row level security;
alter table public.rates  enable row level security;
alter table public.meta   enable row level security;

create policy "public read series" on public.series for select to anon, authenticated using (true);
create policy "public read rates"  on public.rates  for select to anon, authenticated using (true);
create policy "public read meta"   on public.meta   for select to anon, authenticated using (true);

grant select on public.series, public.rates, public.meta, public.latest_rates to anon, authenticated;
