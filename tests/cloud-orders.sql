begin;
insert into auth.users(id,email,role,aud) values('00000000-0000-4000-8000-000000000001','cp-test-one@example.invalid','authenticated','authenticated'),('00000000-0000-4000-8000-000000000002','cp-test-two@example.invalid','authenticated','authenticated');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000001',true);
set local role authenticated;
do $$
declare org uuid; oid uuid; t text; result jsonb;
begin
 org:=public.cp_bootstrap_company('TESTE transacional');
 if public.cp_bootstrap_company('Outro nome')<>org then raise exception 'Bootstrap duplicated company'; end if;
 oid:=public.cp_create_order(org,'{"cliente":"Pessoa teste","telefone":"85999991234","aparelho":"Aparelho teste","defeito":"Tela","valor":"100"}'::jsonb);
 select tracking_token into t from public.cp_service_orders where id=oid;
 perform set_config('cp.test_order',oid::text,true);perform set_config('cp.test_org',org::text,true);perform set_config('cp.test_token',t,true);
 if (select count(*) from public.cp_order_events where service_order_id=oid)<>1 then raise exception 'Opening event missing'; end if;
 begin update public.cp_service_orders set status='delivered' where id=oid;raise exception 'Invalid transition accepted'; exception when raise_exception then if sqlerrm='Invalid transition accepted' then raise; end if; end;
 update public.cp_service_orders set status='diagnosing' where id=oid;
 if (select count(*) from public.cp_order_events where service_order_id=oid)<>2 then raise exception 'Status event missing'; end if;
 result:=public.cp_track_order(t);
 if result->>'status'<>'diagnosing' then raise exception 'Tracking stale'; end if;
 if result ? 'customer' or result ? 'phone' or result ? 'diagnosis' or result ? 'tracking_token' then raise exception 'Tracking leaks fields'; end if;
 update public.cp_service_orders set tracking_enabled=false where id=oid;
 if public.cp_track_order(t) is not null then raise exception 'Disabled token accepted'; end if;
 update public.cp_service_orders set tracking_enabled=true where id=oid;
end $$;
reset role;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000002',true);
set local role authenticated;
do $$
declare other uuid;
begin
 other:=public.cp_bootstrap_company('Outra empresa');
 if exists(select 1 from public.cp_service_orders where id=current_setting('cp.test_order')::uuid) then raise exception 'Cross-tenant read'; end if;
 if exists(select 1 from public.cp_customers where organization_id=current_setting('cp.test_org')::uuid) then raise exception 'Cross-tenant customer read'; end if;
 begin perform public.cp_create_order(current_setting('cp.test_org')::uuid,'{}');raise exception 'Cross-tenant write'; exception when raise_exception then if sqlerrm='Cross-tenant write' then raise; end if; end;
end $$;
reset role;
select set_config('request.jwt.claim.sub','',true);
set local role anon;
do $$
begin
 if public.cp_track_order(current_setting('cp.test_token'))->>'status'<>'diagnosing' then raise exception 'Public tracking failed'; end if;
 if public.cp_track_order(repeat('a',64)) is not null then raise exception 'Unknown token accepted'; end if;
 begin perform public.cp_bootstrap_company('Anonymous');raise exception 'Anonymous bootstrap'; exception when insufficient_privilege then null; end;
 if exists(select 1 from public.cp_service_orders) then raise exception 'Anonymous order listing'; end if;
end $$;
reset role;
rollback;
select 'PASS: opening/status audit, transitions, tenant isolation, public tracking, revocation, anonymous restrictions; all fixtures rolled back' as verification;
