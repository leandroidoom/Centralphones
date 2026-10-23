create table public.cp_order_payments(
 id uuid primary key,
 organization_id uuid not null references public.cp_organizations(id),
 service_order_id uuid not null,
 actor_id uuid not null references auth.users(id),
 amount numeric(12,2) not null check(amount>0),
 method text not null check(method in ('PIX','Dinheiro','Cartão de débito','Cartão de crédito','Transferência')),
 created_at timestamptz not null default now(),
 foreign key(organization_id,service_order_id) references public.cp_service_orders(organization_id,id)
);
alter table public.cp_order_payments enable row level security;
create index cp_payments_order_idx on public.cp_order_payments(service_order_id);
create index cp_payments_org_date_idx on public.cp_order_payments(organization_id,created_at);
create policy cp_payments_read on public.cp_order_payments for select to authenticated using(exists(select 1 from public.cp_memberships m where m.organization_id=cp_order_payments.organization_id and m.user_id=(select auth.uid())));
revoke all on public.cp_order_payments from anon,authenticated;
grant select on public.cp_order_payments to authenticated;

create or replace function cp_private.receive_order_payment(order_id uuid,paid_amount numeric,payment_method text,request_id uuid,deliver boolean default false) returns uuid language plpgsql security definer set search_path='' as $$
declare o public.cp_service_orders; previous public.cp_order_payments; total numeric; paid numeric; who uuid:=auth.uid();
begin
 if who is null then raise exception 'Faça login'; end if;
 select * into o from public.cp_service_orders where id=order_id for update;
 if o.id is null or not exists(select 1 from public.cp_memberships where organization_id=o.organization_id and user_id=who and role in ('owner','admin','attendant')) then raise exception 'Sem permissão para receber esta OS'; end if;
 select * into previous from public.cp_order_payments where id=request_id;
 if previous.id is not null then
  if previous.service_order_id=order_id and previous.amount=paid_amount and previous.method=payment_method then return previous.id; end if;
  raise exception 'Identificador já utilizado';
 end if;
 if o.status in ('cancelled','delivered') then raise exception 'Esta OS não pode receber pagamentos'; end if;
 if request_id is null or paid_amount is null or paid_amount<=0 or paid_amount<>round(paid_amount,2) or paid_amount::text in ('NaN','Infinity','-Infinity') then raise exception 'Valor inválido'; end if;
 if payment_method is null or payment_method not in ('PIX','Dinheiro','Cartão de débito','Cartão de crédito','Transferência') then raise exception 'Pagamento inválido'; end if;
 total:=coalesce(o.final_amount,o.estimated_amount);
 if total is null then raise exception 'Defina o orçamento antes de receber'; end if;
 select coalesce(sum(amount),0) into paid from public.cp_order_payments where service_order_id=order_id;
 if paid_amount>total-paid then raise exception 'O valor excede o saldo pendente'; end if;
 if deliver and (o.status<>'ready' or paid+paid_amount<>total) then raise exception 'Para receber e entregar, a OS deve estar pronta e ser quitada'; end if;
 insert into public.cp_order_payments(id,organization_id,service_order_id,actor_id,amount,method) values(request_id,o.organization_id,order_id,who,paid_amount,payment_method);
 insert into public.cp_order_events(organization_id,service_order_id,actor_id,event_type,description) values(o.organization_id,order_id,who,'payment','Recebimento registrado');
 if deliver then update public.cp_service_orders set status='delivered' where id=order_id; end if;
 return request_id;
end $$;
revoke all on function cp_private.receive_order_payment(uuid,numeric,text,uuid,boolean) from public,anon;
grant execute on function cp_private.receive_order_payment(uuid,numeric,text,uuid,boolean) to authenticated;
create or replace function public.cp_receive_payment(order_id uuid,paid_amount numeric,payment_method text,request_id uuid,deliver boolean default false) returns uuid language sql security invoker set search_path='' as $$select cp_private.receive_order_payment(order_id,paid_amount,payment_method,request_id,deliver)$$;
revoke all on function public.cp_receive_payment(uuid,numeric,text,uuid,boolean) from public,anon;
grant execute on function public.cp_receive_payment(uuid,numeric,text,uuid,boolean) to authenticated;

create or replace function cp_private.validate_order_balance() returns trigger language plpgsql security definer set search_path='' as $$
declare paid numeric; total numeric;
begin
 if auth.uid() is null then raise exception 'Faça login'; end if;
 select coalesce(sum(amount),0) into paid from public.cp_order_payments where service_order_id=old.id;
 total:=coalesce(new.final_amount,new.estimated_amount);
 if paid>0 and (total is null or total<paid) then raise exception 'Valor da OS não pode ser menor que o recebido'; end if;
 if new.status='cancelled' and paid>0 then raise exception 'OS com recebimentos exige estorno antes de cancelar'; end if;
 if new.status='delivered' and (total is null or paid<total) then raise exception 'Quite o saldo antes de entregar'; end if;
 return new;
end $$;
revoke all on function cp_private.validate_order_balance() from public,anon,authenticated;
create trigger cp_order_balance before update on public.cp_service_orders for each row execute function cp_private.validate_order_balance();
