import test from 'node:test';
import assert from 'node:assert/strict';
import {appendServicePayment, receivedCents, readCash} from '../src/lib/service-payments.mjs';
import {cashBalance} from '../src/lib/finance.mjs';
const order = {id:'OS-1',cliente:'Cliente',status:'Em reparo',valor:100.30};
const payment = {id:'REC-1',date:'2026-10-23T12:00:00Z',method:'PIX',amount:40.10};
test('partial and final service payments feed cash exactly once',()=>{
  const first=appendServicePayment(order,[],payment);
  assert.equal(receivedCents(order.id,first),4010);
  const paid=appendServicePayment(order,first,{...payment,id:'REC-2',amount:60.20});
  assert.equal(receivedCents(order.id,paid),10030);
  assert.equal(cashBalance([],paid),10030);
  assert.throws(()=>appendServicePayment(order,paid,{...payment,id:'REC-3',amount:0.01}));
});
test('reject duplicates, cancelled orders, invalid amounts and methods',()=>{
  const first=appendServicePayment(order,[],payment);
  assert.throws(()=>appendServicePayment(order,first,payment));
  assert.throws(()=>appendServicePayment({...order,status:'Cancelado'},[],payment));
  for(const amount of [0,-1,NaN,Infinity,100.31,0.001]) assert.throws(()=>appendServicePayment(order,[],{...payment,amount}));
  assert.throws(()=>appendServicePayment(order,[],{...payment,method:'invalid'}));
});
test('preserves unrelated movements and isolates orders',()=>{
  const previous=[{id:'M-1',kind:'Saída',amount:10},{id:'R-9',orderId:'OS-2',kind:'Entrada',amount:25}];
  const result=appendServicePayment(order,previous,payment);
  assert.deepEqual(result.slice(1),previous);
  assert.equal(receivedCents(order.id,result),4010);
  assert.equal(previous.length,2);
});
test('corrupt storage is rejected instead of overwritten',()=>{
  for(const raw of ['{','null','{}']) assert.throws(()=>readCash({getItem:()=>raw}));
  assert.deepEqual(readCash({getItem:()=>null}),[]);
});
