-- JinYuva: single Login system + Admin dashboard
-- Admin credentials chosen for this setup:
-- ID: JYA-1111
-- DOB: 01/01/01
-- The special admin DOB is stored as text so the exact easy-to-type value is accepted.

create table if not exists public.jinyuva_admin (
  admin_id text primary key,
  admin_dob text not null,
  created_at timestamptz not null default now()
);

insert into public.jinyuva_admin (admin_id, admin_dob)
values ('JYA-1111', '01/01/01')
on conflict (admin_id) do update
set admin_dob = excluded.admin_dob;

alter table public.jinyuva_admin enable row level security;
revoke all on table public.jinyuva_admin from anon, authenticated;

create or replace function public.login_jinyuva(p_membership_id text, p_dob text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id text := upper(trim(p_membership_id));
  v_dob text := trim(p_dob);
  v_member public.members%rowtype;
  v_member_dob date;
begin
  -- Admin is checked first. The exact special DOB is intentionally supported.
  if exists (
    select 1
    from public.jinyuva_admin a
    where upper(a.admin_id) = v_id
      and a.admin_dob = v_dob
  ) then
    return jsonb_build_object(
      'role', 'admin',
      'members', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'membership_id', m.membership_id,
            'name', m.name,
            'phone', m.phone,
            'dob', m.dob,
            'age', m.age,
            'sangh', m.sangh,
            'language', m.language,
            'created_at', m.created_at
          ) order by m.created_at desc
        )
        from public.members m
      ), '[]'::jsonb)
    );
  end if;

  -- Member DOB must be a complete DD/MM/YYYY-style date.
  begin
    if v_dob !~ '^\d{1,2}/\d{1,2}/\d{4}$' then
      return jsonb_build_object('role', 'invalid');
    end if;
    v_member_dob := to_date(v_dob, 'DD/MM/YYYY');
  exception when others then
    return jsonb_build_object('role', 'invalid');
  end;

  select * into v_member
  from public.members m
  where upper(m.membership_id) = v_id
    and m.dob = v_member_dob
  limit 1;

  if found then
    return jsonb_build_object(
      'role', 'member',
      'member', jsonb_build_object(
        'membership_id', v_member.membership_id,
        'public_token', v_member.public_token,
        'name', v_member.name,
        'age', v_member.age,
        'sangh', v_member.sangh
      )
    );
  end if;

  return jsonb_build_object('role', 'invalid');
end;
$$;

revoke all on function public.login_jinyuva(text, text) from public;
grant execute on function public.login_jinyuva(text, text) to anon, authenticated;

-- Verify the function is exposed to the Data API after running this SQL.
select p.proname, has_function_privilege('anon', p.oid, 'EXECUTE') as anon_can_execute
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'login_jinyuva';
