'use client';
import {useEffect,useState} from 'react';
import {Smartphone,RefreshCw} from 'lucide-react';
import {trackOrder} from '@/lib/cloud';
import {stages} from '@/lib/order-flow.mjs';
import '@/components/workspace.css';
type Tracking={order_number:number;status:keyof typeof stages;device:string;company:string;updated_at:string;events:{status:keyof typeof stages;date:string}[]};
export default function TrackingPage(){const [order,setOrder]=useState<Tracking|null>(null),[loading,setLoading]=useState(true),[error,setError]=useState('');
 async function refresh(){setLoading(true);setError('');try{const token=window.location.hash.slice(1);if(!/^[a-f0-9]{64}$/.test(token))throw new Error('Use o link de acompanhamento enviado pela assistência.');const result=await trackOrder(token);if(!result)throw new Error('Este link expirou ou foi desativado. Solicite um novo à assistência.');setOrder(result)}catch(e){setOrder(null);setError(e instanceof Error?e.message:'Não foi possível consultar agora.')}finally{setLoading(false)}}
 useEffect(()=>{refresh();const update=()=>refresh();window.addEventListener('hashchange',update);return()=>window.removeEventListener('hashchange',update)},[]);
 return <main className="cp-workspace"><div className="cp-tracking"><span className="cp-eyebrow">ACOMPANHAMENTO DO REPARO</span><h2>✦ {order?.company||'Centralphones'}</h2>{order?<><div className="cp-hero"><Smartphone size={38}/><p>OS #{String(order.order_number).padStart(4,'0')} · {order.device}</p><h1>{stages[order.status]}</h1><p>Atualizado em {new Date(order.updated_at).toLocaleString('pt-BR')}</p></div><section className="cp-card"><h2>Etapas do seu atendimento</h2><div className="cp-timeline">{order.events.map((e,i)=><article key={i}><b>{stages[e.status]||'Atualização'}</b><small>{new Date(e.date).toLocaleString('pt-BR')}</small></article>)}</div></section></>:<section className="cp-card"><h1>{loading?'Consultando seu aparelho…':'Acompanhamento indisponível'}</h1>{error&&<p role="alert">{error}</p>}</section>}<button disabled={loading} onClick={refresh}><RefreshCw size={16}/>{loading?'Atualizando…':'Atualizar situação'}</button><p>Para orçamento, prazo ou dúvidas, fale diretamente com a assistência que enviou este link.</p></div></main>
}
