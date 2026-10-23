'use client';
import {useEffect,useState} from 'react';
import Link from 'next/link';
import {Menu,Plus,Sun,Moon,Settings2,Wrench,LayoutDashboard,Wallet,Package,ShoppingCart,Users,X} from 'lucide-react';
import './workspace.css';
const links=[['Painel','/',LayoutDashboard],['Ordens de serviço','/ordens-servico',Wrench],['PDV / Vendas','/pdv',ShoppingCart],['Caixa das OS','/caixa/nuvem',Wallet],['Caixa local / PDV','/caixa',Wallet],['Estoque','/estoque',Package],['Clientes locais','/cadastros/clientes',Users]] as const;
const colors={'Azul Royal':'#1769ff','Roxo Premium':'#8054e8','Verde Esmeralda':'#059669','Laranja Energy':'#ea7c26'};
export default function Workspace({children,action}:{children:React.ReactNode;action?:()=>void}){
 const [menu,setMenu]=useState(false),[settings,setSettings]=useState(false),[dark,setDark]=useState(false),[color,setColor]=useState('#1769ff'),[names,setNames]=useState<Record<string,string>>({}),[loaded,setLoaded]=useState(false);
 useEffect(()=>{try{const p=JSON.parse(localStorage.getItem('centralphones:workspace')||'{}');setNames(p.names||{});setDark(!!p.dark);setColor(p.color||'#1769ff')}catch{}setLoaded(true)},[]);
 useEffect(()=>{if(loaded)localStorage.setItem('centralphones:workspace',JSON.stringify({names,dark,color}))},[names,dark,color,loaded]);
 return <div className={'cp-workspace '+(dark?'cp-dark':'')} style={{'--cp-accent':color} as React.CSSProperties}>
 <aside className={'cp-sidebar '+(menu?'cp-open':'')}><Link className="cp-brand" href="/">✦ Centralphones</Link><p className="cp-caption">SEU NEGÓCIO, ORGANIZADO</p><nav>{links.map(([name,url,Icon])=><Link href={url} key={url} onClick={()=>setMenu(false)}><Icon size={18}/>{names[url]||name}</Link>)}</nav><div className="cp-sidebar-note"><b>Assistência conectada</b><p>OS e fotos salvas na sua conta.</p><Link href="/ordens-servico/local">Consultar OS antigas deste navegador →</Link></div></aside>
 <div className="cp-main"><header className="cp-topbar"><button aria-label="Abrir menu" onClick={()=>setMenu(!menu)}><Menu size={20}/></button><span>Gestão da assistência</span><div className="cp-toolbar"><button aria-label="Personalizar menus" onClick={()=>setSettings(true)}><Settings2 size={18}/></button><button aria-label="Alternar tema" onClick={()=>setDark(!dark)}>{dark?<Sun size={18}/>:<Moon size={18}/>}</button><b className="cp-avatar">CP</b></div></header><div className="cp-content">{children}</div></div>
 {action&&<button className="cp-fab" aria-label="Abrir nova ordem de serviço" onClick={action}><Plus size={22}/><span>Nova OS</span></button>}
 {settings&&<div className="cp-overlay"><section className="cp-dialog" role="dialog" aria-modal="true" aria-labelledby="settings-title"><div className="cp-heading"><h2 id="settings-title">Do seu jeito</h2><button aria-label="Fechar personalização" onClick={()=>setSettings(false)}><X/></button></div><p>Personalize os nomes do menu neste navegador.</p>{links.map(([name,url])=><label key={url}>{name}<input maxLength={32} value={names[url]??name} onChange={e=>setNames({...names,[url]:e.target.value})}/></label>)}<label>Paleta<select value={color} onChange={e=>setColor(e.target.value)}>{Object.entries(colors).map(([n,c])=><option value={c} key={c}>{n}</option>)}</select></label><button className="cp-primary" onClick={()=>setSettings(false)}>Concluir</button></section></div>}
 </div>
}
