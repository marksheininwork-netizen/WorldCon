-- WorldCon schema. Run in the Supabase SQL Editor of a fresh project.
-- Buyer-first marketplace with protected company ownership, offers, and messages.
create extension if not exists pgcrypto;

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 120),
  description text not null default '',
  location text not null default '',
  website text,
  capabilities text[] not null default '{}',
  created_at timestamptz not null default now(),
  unique(owner_id),
  constraint website_http check (website is null or website ~* '^https?://')
);
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  company_id uuid references public.companies(id) on delete set null,
  full_name text not null default '',
  role text not null default 'buyer' check (role in ('buyer','manufacturer')),
  created_at timestamptz not null default now()
);
create table public.requests (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  created_by uuid not null references auth.users(id),
  title text not null check (char_length(trim(title)) between 5 and 120),
  category text not null,
  description text not null check (char_length(trim(description)) between 30 and 10000),
  quantity numeric(15,2) not null check (quantity > 0),
  unit text not null default 'pieces',
  budget_min numeric(15,2) check (budget_min >= 0),
  budget_max numeric(15,2) check (budget_max >= 0),
  currency text not null default 'USD' check (currency = 'USD'),
  location text not null default 'Worldwide',
  deadline date,
  status text not null default 'open' check (status in ('open','awarded','closed')),
  created_at timestamptz not null default now(),
  constraint budget_order check (budget_max is null or budget_min is null or budget_max >= budget_min)
);
create table public.offers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.requests(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  created_by uuid not null references auth.users(id),
  price numeric(15,2) not null check (price > 0),
  lead_time_days integer not null check (lead_time_days between 1 and 3650),
  message text not null check (char_length(trim(message)) between 20 and 10000),
  status text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  unique(request_id,company_id)
);
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  offer_id uuid not null references public.offers(id) on delete cascade,
  sender_id uuid not null references auth.users(id),
  body text not null check (char_length(trim(body)) between 1 and 4000),
  created_at timestamptz not null default now()
);
create index requests_status_created_idx on public.requests(status,created_at desc);
create index requests_company_idx on public.requests(company_id);
create index offers_request_idx on public.offers(request_id);
create index offers_company_idx on public.offers(company_id);
create index messages_offer_created_idx on public.messages(offer_id,created_at);
create unique index only_one_accepted_offer on public.offers(request_id) where status='accepted';

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,full_name,role)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),case when new.raw_user_meta_data->>'role'='manufacturer' then 'manufacturer' else 'buyer' end)
 on conflict(id) do nothing;
 return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.is_company_owner(p_company uuid) returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.companies c where c.id=p_company and c.owner_id=(select auth.uid()));
$$;
create or replace function public.is_manufacturer() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='manufacturer');
$$;
create or replace function public.is_buyer() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='buyer');
$$;
create or replace function public.can_access_offer(p_offer uuid) returns boolean language sql stable security definer set search_path = '' as $$
 select exists (
  select 1 from public.offers o join public.requests r on r.id=o.request_id
  where o.id=p_offer and (public.is_company_owner(o.company_id) or public.is_company_owner(r.company_id))
 );
$$;

alter table public.companies enable row level security;
alter table public.profiles enable row level security;
alter table public.requests enable row level security;
alter table public.offers enable row level security;
alter table public.messages enable row level security;

create policy companies_read on public.companies for select to anon, authenticated using (true);
create policy companies_create on public.companies for insert to authenticated with check (owner_id=(select auth.uid()));
create policy companies_edit on public.companies for update to authenticated using (owner_id=(select auth.uid())) with check (owner_id=(select auth.uid()));
create policy profiles_read on public.profiles for select to authenticated using (id=(select auth.uid()) or exists(select 1 from public.messages m where m.sender_id=profiles.id and public.can_access_offer(m.offer_id)));
create policy profiles_create on public.profiles for insert to authenticated with check (id=(select auth.uid()) and (company_id is null or public.is_company_owner(company_id)));
create policy profiles_update on public.profiles for update to authenticated using (id=(select auth.uid())) with check(id=(select auth.uid()) and (company_id is null or public.is_company_owner(company_id)));
create policy requests_public_read on public.requests for select to anon, authenticated using (status='open' or public.is_company_owner(company_id) or exists(select 1 from public.offers o where o.request_id=requests.id and public.is_company_owner(o.company_id)));
create policy requests_create on public.requests for insert to authenticated with check (created_by=(select auth.uid()) and public.is_company_owner(company_id) and public.is_buyer() and status='open');
create policy requests_update on public.requests for update to authenticated using (public.is_company_owner(company_id)) with check (public.is_company_owner(company_id) and created_by=(select auth.uid()));
create policy offers_read on public.offers for select to authenticated using (public.can_access_offer(id));
create policy offers_create on public.offers for insert to authenticated with check (created_by=(select auth.uid()) and public.is_company_owner(company_id) and public.is_manufacturer() and status='pending' and exists(select 1 from public.requests r where r.id=request_id and r.status='open' and r.company_id<>offers.company_id));
create policy messages_read on public.messages for select to authenticated using (public.can_access_offer(offer_id));
create policy messages_create on public.messages for insert to authenticated with check (sender_id=(select auth.uid()) and public.can_access_offer(offer_id));

-- Avoid direct changes to immutable or privileged fields, even by otherwise authorized clients.
create or replace function public.protect_request_fields() returns trigger language plpgsql set search_path = '' as $$
begin
 if old.company_id is distinct from new.company_id or old.created_by is distinct from new.created_by then
  raise exception 'Cannot reassign sourcing request';
 end if;
 if old.status <> 'open' and new.status <> old.status then
  raise exception 'Cannot reopen or change a completed request';
 end if;
 if new.status = 'awarded' and old.status <> 'awarded' then
  raise exception 'Award must be accepted through accept_offer';
 end if;
 return new;
end;
$$;
create trigger protect_request_fields before update on public.requests for each row execute function public.protect_request_fields();
create or replace function public.protect_company_owner() returns trigger language plpgsql set search_path = '' as $$
begin
 if old.owner_id is distinct from new.owner_id then raise exception 'Cannot transfer company ownership'; end if;
 return new;
end;
$$;
create trigger protect_company_owner before update on public.companies for each row execute function public.protect_company_owner();

create or replace function public.accept_offer(p_offer_id uuid) returns void language plpgsql security definer set search_path = '' as $$
declare v_request_id uuid; v_company_id uuid; v_status text;
begin
 select o.request_id,r.company_id,r.status into v_request_id,v_company_id,v_status
 from public.offers o join public.requests r on r.id=o.request_id where o.id=p_offer_id for update of r;
 if v_request_id is null then raise exception 'Offer not found'; end if;
 if not public.is_company_owner(v_company_id) then raise exception 'Not authorized'; end if;
 if v_status <> 'open' then raise exception 'Request is no longer open'; end if;
 update public.offers set status=case when id=p_offer_id then 'accepted' else 'declined' end where request_id=v_request_id;
 -- Update status without triggering general client restrictions.
 update public.requests set status='awarded' where id=v_request_id;
end;
$$;
-- Permit the privileged award routine while disallowing direct status changes.
create or replace function public.protect_request_fields() returns trigger language plpgsql set search_path = '' as $$
begin
 if old.company_id is distinct from new.company_id or old.created_by is distinct from new.created_by then raise exception 'Cannot reassign sourcing request'; end if;
 if old.status <> 'open' and new.status <> old.status then raise exception 'Cannot reopen or change a completed request'; end if;
 if new.status = 'awarded' and old.status <> 'awarded' and current_user <> 'postgres' then
  raise exception 'Award must be accepted through accept_offer';
 end if;
 return new;
end;
$$;
revoke all on function public.accept_offer(uuid) from public, anon;
grant execute on function public.accept_offer(uuid) to authenticated;
revoke all on function public.is_company_owner(uuid) from public;
revoke all on function public.is_manufacturer() from public;
revoke all on function public.is_buyer() from public;
revoke all on function public.can_access_offer(uuid) from public;
grant execute on function public.is_company_owner(uuid) to authenticated, anon;
grant execute on function public.is_manufacturer() to authenticated;
grant execute on function public.is_buyer() to authenticated;
grant execute on function public.can_access_offer(uuid) to authenticated;
