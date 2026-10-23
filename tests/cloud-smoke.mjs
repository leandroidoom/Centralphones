// Read-only HTTP checks against the configured project. No customer data is requested.
import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const config=await readFile(new URL('../src/lib/cloud-config.ts',import.meta.url),'utf8');
const url=config.match(/cloudUrl = '([^']+)'/)[1];
const key=JSON.parse(config.match(/publishableKey = ("[^"]+")/)[1]);
const headers={apikey:key,'Content-Type':'application/json'};
const res=await fetch(url+'/rest/v1/rpc/cp_track_order',{method:'POST',headers,body:JSON.stringify({token:'0'.repeat(64)}),signal:AbortSignal.timeout(15000)});
assert.equal(res.status,200);assert.equal(await res.json(),null);
const denied=await fetch(url+'/rest/v1/cp_service_orders?select=id&limit=1',{headers,signal:AbortSignal.timeout(15000)});
assert.ok(denied.status===200||denied.status===401||denied.status===403);
if(denied.status===200)assert.deepEqual(await denied.json(),[]);
console.log('PASS: tracking RPC reachable and anonymous order listing protected');
