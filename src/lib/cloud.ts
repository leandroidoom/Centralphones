import {cloudUrl,publishableKey} from './cloud-config';
type Session={access_token:string;refresh_token:string;expires_at:number;expires_in?:number;user?:{id:string;email?:string}};
const sessionKey='centralphones:cloud-session';
let refreshing:Promise<Session>|null=null;
function saved():Session|null {try{return JSON.parse(sessionStorage.getItem(sessionKey)||'null')}catch{return null}}
function save(s:Session){s.expires_at=s.expires_at||Math.floor(Date.now()/1000)+(s.expires_in||3600);sessionStorage.setItem(sessionKey,JSON.stringify(s));return s}
async function raw(path:string,options:RequestInit={},token?:string){
 const res=await fetch(cloudUrl+path,{...options,headers:{apikey:publishableKey,...(token?{Authorization:'Bearer '+token}:{}),...(!(options.body instanceof Blob)?{'Content-Type':'application/json'}:{}),...options.headers},cache:'no-store'});
 const data=await res.json().catch(()=>null);
 if(!res.ok)throw new Error(data?.msg||data?.message||data?.error_description||data?.error||'Não foi possível concluir a operação.');return data;
}
async function current(){let s=saved();if(s&&s.expires_at<Date.now()/1000+60){if(!refreshing)refreshing=raw('/auth/v1/token?grant_type=refresh_token',{method:'POST',body:JSON.stringify({refresh_token:s.refresh_token})}).then(save).finally(()=>{refreshing=null});try{s=await refreshing}catch{sessionStorage.removeItem(sessionKey);throw new Error('Sua sessão expirou. Entre novamente.')}}return s}
export async function request(path:string,options:RequestInit={}){const s=await current();if(!s)throw new Error('Entre na sua conta para continuar.');return raw(path,options,s.access_token)}
export async function restoreUser(){const s=await current();if(!s)return null;return raw('/auth/v1/user',{},s.access_token)}
export async function login(email:string,password:string){const s=await raw('/auth/v1/token?grant_type=password',{method:'POST',body:JSON.stringify({email,password})});save(s);return s.user}
export async function signup(email:string,password:string){const result=await raw('/auth/v1/signup',{method:'POST',body:JSON.stringify({email,password})});if(result.access_token)save(result);return result}
export async function verifyEmail(email:string,token:string){const s=await raw('/auth/v1/verify',{method:'POST',body:JSON.stringify({email,token,type:'signup'})});save(s);return s.user}
export async function logout(){const s=saved();try{if(s)await raw('/auth/v1/logout',{method:'POST'},s.access_token)}finally{sessionStorage.removeItem(sessionKey)}}
export const rpc=(name:string,body:unknown)=>request('/rest/v1/rpc/'+name,{method:'POST',body:JSON.stringify(body)});
export const trackOrder=(token:string)=>raw('/rest/v1/rpc/cp_track_order',{method:'POST',body:JSON.stringify({token})});
export async function listOrders(org:string){return request('/rest/v1/cp_service_orders?organization_id=eq.'+org+'&select=*,customer:cp_customers(full_name,phone),device:cp_devices(model,serial_number)&order=created_at.desc&limit=500')}
export async function updateOrder(id:string,patch:Record<string,unknown>){const rows=await request('/rest/v1/cp_service_orders?id=eq.'+id,{method:'PATCH',headers:{Prefer:'return=representation'},body:JSON.stringify(patch)});if(!rows.length)throw new Error('Ordem não encontrada ou acesso negado.');return rows[0]}
export async function uploadPhoto(org:string,order:string,file:File){if(!['image/jpeg','image/png','image/webp'].includes(file.type)||file.size>5*1024*1024)throw new Error('Selecione JPG, PNG ou WebP de até 5 MB.');const ext=file.type.split('/')[1];return request('/storage/v1/object/cp-order-photos/'+org+'/'+order+'/'+crypto.randomUUID()+'.'+ext,{method:'POST',headers:{'Content-Type':file.type,'x-upsert':'false'},body:file})}
export async function listPhotos(org:string,order:string){const prefix=org+'/'+order;const rows=await request('/storage/v1/object/list/cp-order-photos',{method:'POST',body:JSON.stringify({prefix,limit:100,sortBy:{column:'created_at',order:'desc'}})});return Promise.all(rows.filter((r:{id?:string})=>r.id).map(async(r:{name:string})=>{const signed=await request('/storage/v1/object/sign/cp-order-photos/'+prefix+'/'+r.name,{method:'POST',body:JSON.stringify({expiresIn:900})});return {name:r.name,url:cloudUrl+'/storage/v1'+signed.signedURL}}))}
