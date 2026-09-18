-- JinYuva Supabase database schema
-- Run this in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  membership_id text unique not null,
  public_token text unique not null default encode(gen_random_bytes(18), 'hex'),
  name text not null,
  phone text unique not null,
  dob date not null,
  sangh text not null,
  language text not null default 'en' check (language in ('en','gu','hi')),
  age integer not null,
  created_at timestamptz not null default now()
);

create index if not exists members_sangh_idx on public.members (lower(sangh));
create index if not exists members_created_at_idx on public.members (created_at desc);

alter table public.members enable row level security;

-- No direct table reads/writes for the public anon client.
revoke all on table public.members from anon, authenticated;

create or replace function public.register_member(
  p_name text,
  p_phone text,
  p_dob date,
  p_sangh text,
  p_language text default 'en'
)
returns table (
  membership_id text,
  public_token text,
  name text,
  age integer,
  sangh text,
  already_registered boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  existing public.members%rowtype;
  new_id text;
  calculated_age integer;
begin
  if p_name is null or length(trim(p_name)) = 0 then
    raise exception 'Name is required';
  end if;

  if p_phone !~ '^[0-9]{10}$' then
    raise exception 'Invalid phone number';
  end if;

  if p_dob is null then
    raise exception 'Date of birth is required';
  end if;

  calculated_age := extract(year from age(current_date, p_dob))::integer;

  if calculated_age < 10 or calculated_age > 120 then
    raise exception 'Age is outside the allowed range';
  end if;

  if p_sangh is null or trim(p_sangh) = '' or trim(p_sangh) ~ '^[-.\\s]+$' then
    raise exception 'Sangh is required';
  end if;

  select * into existing from public.members where phone = p_phone limit 1;
  if found then
    return query select existing.membership_id, existing.public_token, existing.name, existing.age, existing.sangh, true;
    return;
  end if;

  new_id := 'JY-' || lpad((floor(random()*900000)+100000)::bigint::text, 6, '0');
  while exists(select 1 from public.members where membership_id = new_id) loop
    new_id := 'JY-' || lpad((floor(random()*900000)+100000)::bigint::text, 6, '0');
  end loop;

  insert into public.members(membership_id, name, phone, dob, sangh, language, age)
  values(new_id, trim(p_name), p_phone, p_dob, trim(p_sangh), coalesce(p_language,'en'), calculated_age)
  returning * into existing;

  return query select existing.membership_id, existing.public_token, existing.name, existing.age, existing.sangh, false;
end;
$$;

grant execute on function public.register_member(text,text,date,text,text) to anon, authenticated;

create or replace function public.get_member_by_token(p_token text)
returns table (
  membership_id text,
  public_token text,
  name text,
  age integer,
  sangh text
)
language sql
security definer
set search_path = public
as $$
  select m.membership_id, m.public_token, m.name, m.age, m.sangh
  from public.members m
  where m.public_token = p_token
  limit 1;
$$;

grant execute on function public.get_member_by_token(text) to anon, authenticated;

-- For Excel/CSV sharing, Supabase Dashboard can export the members table.
-- Do not share phone/DOB columns unless necessary; treat them as personal data.
