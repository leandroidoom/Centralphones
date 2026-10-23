import test from 'node:test';
import assert from 'node:assert/strict';
import {currencyCents, cartTotal, canSell, cashBalance} from '../src/lib/finance.mjs';
test('currency avoids floating point errors', () => assert.equal(currencyCents(0.1 + 0.2), 30));
test('cart calculates quantity and cents', () => assert.equal(cartTotal([{price: 10.55, qty: 3}, {price: 0.1, qty: 1}]), 3175));
test('cart rejects invalid quantities', () => assert.throws(() => cartTotal([{price: 10, qty: 0}]), RangeError));
test('stock prevents overselling', () => {assert.equal(canSell([{id:'a',qty:3}],[{id:'a',quantidade:2}]),false);assert.equal(canSell([{id:'a',qty:2}],[{id:'a',quantidade:2}]),true)});
test('cash subtracts expenses', () => assert.equal(cashBalance([{total: 100}], [{kind:'Saída',amount:25},{kind:'Entrada',amount:5}]), 8000));
