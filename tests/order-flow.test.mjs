import test from 'node:test';
import assert from 'node:assert/strict';
import {brazilPhone,customerMessage,trackingLink,stages,transitions} from '../src/lib/order-flow.mjs';
test('WhatsApp accepts local and country-prefixed Brazilian numbers',()=>{assert.equal(brazilPhone('(85) 99999-1234'),'5585999991234');assert.equal(brazilPhone('+55 85 99999-1234'),'5585999991234');assert.throws(()=>brazilPhone('123'))});
test('every workflow stage has a message and valid next stages',()=>{for(const status of Object.keys(stages)){const text=customerMessage({status,order_number:1},'Centralphones','https://example.org/acompanhar#abc');assert.ok(text.includes('OS #1'));assert.ok(!text.includes('undefined'));for(const next of transitions[status])assert.ok(stages[next])}assert.deepEqual(transitions.delivered,[])});
test('tracking token stays in fragment and cannot alter destination',()=>{const token='a'.repeat(64);const url=new URL(trackingLink('https://example.org',token));assert.equal(url.pathname,'/acompanhar');assert.equal(url.search,'');assert.equal(url.hash,'#'+token);assert.throws(()=>trackingLink('https://example.org','../admin'))});
