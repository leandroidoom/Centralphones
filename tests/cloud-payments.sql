begin;
insert into auth.users(id,email,role,aud) values('00000000-0000-4000-8000-000000000003','cp-payment-test@example.invalid','authenticated','authenticated');
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000003',true);
set local role authenticated;
do $$
declare org uuid; oid uuid; receipt uuid:=gen_random_uuid();
begin
 org:=public.cp_bootstrap_company('TESTE pagamento transacional');
 oid:=public.cp_create_order(org,'{"cliente":"Teste","aparelho":"Telefone","defeito":"Tela","valor":"100"}');
 perform public.cp_receive_payment(oid,40,'PIX',receipt,false);
 perform public.cp_receive_payment(oid,40,'PIX',receipt,false);
 if (select sum(amount) from public.cp_order_payments where service_order_id=oid)<>40 then raise exception 'Duplicate payment'; end if;
 begin perform public.cp_receive_payment(oid,61,'PIX',gen_random_uuid(),false);raise exception 'Overpayment accepted'; exception when raise_exception then if sqlerrm='Overpayment accepted' then raise; end if; end;
 begin update public.cp_service_orders set estimated_amount=30 where id=oid;raise exception 'Price below paid accepted'; exception when raise_exception then if sqlerrm='Price below paid accepted' then raise; end if; end;
 begin update public.cp_service_orders set status='cancelled' where id=oid;raise exception 'Paid order cancelled'; exception when raise_exception then if sqlerrm='Paid order cancelled' then raise; end if; end;
 update public.cp_service_orders set status='diagnosing' where id=oid;
 update public.cp_service_orders set status='approved' where id=oid;
 update public.cp_service_orders set status='in_repair' where id=oid;
 update public.cp_service_orders set status='ready' where id=oid;
 begin update public.cp_service_orders set status='delivered' where id=oid;raise exception 'Unpaid delivery accepted'; exception when raise_exception then if sqlerrm='Unpaid delivery accepted' then raise; end if; end;
 perform public.cp_receive_payment(oid,60,'Dinheiro',gen_random_uuid(),true);
 if (select status from public.cp_service_orders where id=oid)<>'delivered' then raise exception 'Checkout failed'; end if;
 if (select sum(amount) from public.cp_order_payments where service_order_id=oid)<>100 then raise exception 'Balance incorrect'; end if;
end $$;
reset role;
rollback;
select 'PASS: partial payment, idempotency, overpayment, price protection, cancellation protection, unpaid delivery and atomic checkout; fixtures rolled back' as verification;
