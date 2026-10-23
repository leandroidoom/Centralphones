-- Additive cloud OS extension. Existing tenant tables and data are preserved.
create schema if not exists cp_private;
revoke all on schema cp_private from public;
grant usage on schema cp_private to authenticated, anon;
alter table public.cp_service_orders add column if not exists technician text not null default '';
alter table public.cp_service_orders add column if not exists accessories text not null default '';
alter table public.cp_service_orders add column if not exists checklist jsonb not null default '{}'::jsonb;
alter table public.cp_service_orders add column if not exists tracking_token text not null default replace(gen_random_uuid()::text || gen_random_uuid()::text,'-','');
create unique index if not exists cp_orders_tracking_token_idx on public.cp_service_orders(tracking_token);
alter table public.cp_service_orders add column if not exists tracking_enabled boolean not null default true;
alter table public.cp_service_orders add column if not exists tracking_expires_at timestamptz not null default now()+interval '180 days';
alter table public.cp_order_events add column if not exists status text;

create or replace function cp_private.bootstrap_company(company_name text) returns uuid language plpgsql security definer set search_path='' as $$
declare org uuid; who uuid:=auth.uid();
begin
 if who is null then raise exception 'Faça login para continuar'; end if;
 perform pg_advisory_xact_lock(hashtext(who::text));
 select organization_id into org from public.cp_memberships where user_id=who limit 1;
 if org is not null then return org; end if;
 if length(trim(company_name))<2 or length(company_name)>120 then raise exception 'Nome da empresa inválido'; end if;
 insert into public.cp_organizations(name,slug) values(trim(company_name),gen_random_uuid()::text) returning id into org;
 insert into public.cp_memberships(organization_id,user_id,role) values(org,who,'owner');
 return org;
end $$;
revoke all on function cp_private.bootstrap_company(text) from public,anon;
grant execute on function cp_private.bootstrap_company(text) to authenticated;
create or replace function public.cp_bootstrap_company(company_name text) returns uuid language sql security invoker set search_path='' as $$ select cp_private.bootstrap_company(company_name) $$;
revoke all on function public.cp_bootstrap_company(text) from public,anon;
grant execute on function public.cp_bootstrap_company(text) to authenticated;

create or replace function public.cp_create_order(org_id uuid, payload jsonb) returns uuid language plpgsql security invoker set search_path='' as $$
declare customer uuid; device uuid; order_id uuid;
begin
 if auth.uid() is null or not exists(select 1 from public.cp_memberships where organization_id=org_id and user_id=auth.uid()) then raise exception 'Acesso negado'; end if;
 if coalesce(length(trim(payload->>'cliente')),0)<2 or coalesce(length(trim(payload->>'aparelho')),0)<2 or coalesce(length(trim(payload->>'defeito')),0)<2 then raise exception 'Preencha cliente, aparelho e defeito'; end if;
 insert into public.cp_customers(organization_id,full_name,phone) values(org_id,trim(payload->>'cliente'),payload->>'telefone') returning id into customer;
 insert into public.cp_devices(organization_id,customer_id,model,serial_number) values(org_id,customer,payload->>'aparelho',payload->>'imei') returning id into device;
 insert into public.cp_service_orders(organization_id,customer_id,device_id,problem_description,technician,accessories,checklist,estimated_amount)
 values(org_id,customer,device,payload->>'defeito',coalesce(payload->>'tecnico',''),coalesce(payload->>'acessorios',''),coalesce(payload->'checklist','{}'),nullif(payload->>'valor','')::numeric) returning id into order_id;
 return order_id;
end $$;
revoke all on function public.cp_create_order(uuid,jsonb) from public,anon;
grant execute on function public.cp_create_order(uuid,jsonb) to authenticated;

create or replace function cp_private.audit_order() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not exists(select 1 from public.cp_memberships where organization_id=new.organization_id and user_id=auth.uid()) then raise exception 'Acesso negado'; end if;
 if TG_OP='UPDATE' then
  if new.organization_id<>old.organization_id then raise exception 'Empresa da OS não pode ser alterada'; end if;
  if new.status<>old.status and not (case old.status
   when 'received' then new.status in ('diagnosing','cancelled')
   when 'diagnosing' then new.status in ('waiting_approval','approved','cancelled')
   when 'waiting_approval' then new.status in ('approved','cancelled','diagnosing')
   when 'approved' then new.status in ('in_repair','waiting_parts','cancelled')
   when 'in_repair' then new.status in ('waiting_parts','ready','cancelled')
   when 'waiting_parts' then new.status in ('in_repair','cancelled')
   when 'ready' then new.status in ('delivered','in_repair')
   else false end) then raise exception 'Transição de etapa inválida'; end if;
 end if;
 new.updated_at=now();
 return new;
end $$;
revoke all on function cp_private.audit_order() from public,anon,authenticated;
create trigger cp_validate_order before insert or update on public.cp_service_orders for each row execute function cp_private.audit_order();
create or replace function cp_private.record_order_event() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Acesso negado'; end if;
 if TG_OP='INSERT' then
 insert into public.cp_order_events(organization_id,service_order_id,actor_id,event_type,description,status) values(new.organization_id,new.id,auth.uid(),'status','Abertura da ordem',new.status);
 elsif new.status<>old.status then
 insert into public.cp_order_events(organization_id,service_order_id,actor_id,event_type,description,status) values(new.organization_id,new.id,auth.uid(),'status','Atualização de etapa',new.status);
 end if; return new;
end $$;
revoke all on function cp_private.record_order_event() from public,anon,authenticated;
create trigger cp_record_order after insert or update on public.cp_service_orders for each row execute function cp_private.record_order_event();
revoke insert,update,delete on public.cp_order_events from authenticated;
grant select on public.cp_order_events to authenticated;
grant select on public.cp_memberships,public.cp_organizations to authenticated;
grant select,insert,update on public.cp_customers,public.cp_devices,public.cp_service_orders to authenticated;
grant usage on sequence public.cp_service_orders_order_number_seq to authenticated;

-- Public capability endpoint: exact 256-bit random token, expiry, no PII or internal notes.
-- Definer is deliberately isolated; anon cannot SELECT the underlying tables.
create or replace function cp_private.track_order(token text) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('order_number',o.order_number,'status',o.status,'device',d.model,'company',c.name,'updated_at',o.updated_at,
 'events',(select coalesce(jsonb_agg(jsonb_build_object('status',e.status,'date',e.created_at) order by e.created_at),'[]'::jsonb) from public.cp_order_events e where e.service_order_id=o.id and e.event_type='status'))
 from public.cp_service_orders o join public.cp_organizations c on c.id=o.organization_id left join public.cp_devices d on d.id=o.device_id
 where length(token)=64 and o.tracking_token=token and o.tracking_enabled and o.tracking_expires_at>now() limit 1;
$$;
revoke all on function cp_private.track_order(text) from public;
grant execute on function cp_private.track_order(text) to anon,authenticated;
create or replace function public.cp_track_order(token text) returns jsonb language sql stable security invoker set search_path='' as $$ select cp_private.track_order(token) $$;
revoke all on function public.cp_track_order(text) from public;
grant execute on function public.cp_track_order(text) to anon,authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('cp-order-photos','cp-order-photos',false,5242880,array['image/jpeg','image/png','image/webp']) on conflict(id) do nothing;
create policy cp_photos_read on storage.objects for select to authenticated using(bucket_id='cp-order-photos' and exists(select 1 from public.cp_service_orders o where o.organization_id::text=(storage.foldername(name))[1] and o.id::text=(storage.foldername(name))[2]));
create policy cp_photos_insert on storage.objects for insert to authenticated with check(bucket_id='cp-order-photos' and exists(select 1 from public.cp_service_orders o where o.organization_id::text=(storage.foldername(name))[1] and o.id::text=(storage.foldername(name))[2]));
