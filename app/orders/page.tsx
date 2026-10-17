'use client';
import { useEffect, useState } from 'react';
import { PackageCheck, RefreshCw } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { lifecycle, type OrderStatus } from '@/lib/types';
import { SiteHeader } from '@/components/site-header';

type Order = { id:string; status:OrderStatus; total_amount:number; created_at:string; order_items?:{quantity:number;product_name:string}[] };
const label=(status:string)=>status.replaceAll('_',' ').toLowerCase().replace(/\b\w/g,c=>c.toUpperCase());
const milestones: Record<OrderStatus,string> = { PLACED:'Placed', ACCEPTED:'Accepted', PREPARING:'Preparing', READY_FOR_PICKUP:'Ready', OUT_FOR_DELIVERY:'On the way', DELIVERED:'Delivered', CANCELLED:'Cancelled' };

export default function Orders(){
 const [orders,setOrders]=useState<Order[]>([]),[state,setState]=useState<'loading'|'guest'|'ready'>('loading');
 const load=async()=>{const s=createClient();const {data:{user}}=await s.auth.getUser();if(!user){setState('guest');return;}const {data}=await s.from('orders').select('*,order_items(quantity,product_name)').eq('customer_id',user.id).order('created_at',{ascending:false});setOrders((data||[]) as Order[]);setState('ready');};
 useEffect(()=>{load();const s=createClient();const c=s.channel('customer-orders').on('postgres_changes',{event:'*',schema:'public',table:'orders'},load).subscribe();return()=>{s.removeChannel(c)};},[]);
 if(state==='loading')return <><SiteHeader/><main className="shell py-12">Loading your orders…</main></>;
 if(state==='guest')return <><SiteHeader/><main className="shell grid min-h-[70vh] place-items-center text-center"><div><PackageCheck className="mx-auto text-brand-600" size={48}/><h1 className="mt-4 text-2xl font-black">Your order history</h1><p className="mt-2 text-stone-500">Please sign in from the home page to view your orders.</p></div></main></>;
 return <><SiteHeader/><main className="shell max-w-3xl py-8"><div className="flex justify-between"><div><p className="text-sm font-bold text-brand-600">MY ORDERS</p><h1 className="text-3xl font-black">Track your treats</h1></div><button aria-label="Refresh orders" onClick={load} className="btn-secondary !p-3"><RefreshCw size={18}/></button></div><div className="mt-7 space-y-4">{orders.length===0?<div className="card p-10 text-center text-stone-500">No orders yet. Your sweet tooth knows where to go.</div>:orders.map(o=><OrderCard key={o.id} order={o}/>)}</div></main></>;
}

function OrderCard({order}:{order:Order}){
 const current=lifecycle.indexOf(order.status); const progress=Math.max(0,current)/(lifecycle.length-1)*100;
 return <article className="card p-5"><div className="flex items-start justify-between gap-3"><div><p className="font-black">Order #{order.id.slice(0,8).toUpperCase()}</p><p className="mt-1 text-sm text-stone-500">{new Date(order.created_at).toLocaleDateString('en-IN',{day:'numeric',month:'short'})} · ₹{order.total_amount}</p></div><span className="status shrink-0 self-start bg-brand-50 text-brand-700">{label(order.status)}</span></div><p className="mt-3 text-sm text-stone-600">{order.order_items?.map(item=>`${item.quantity}× ${item.product_name||'Sweet item'}`).join(', ')||'Order details will be updated shortly'}</p>{order.status!=='CANCELLED'&&<div className="mt-7 overflow-x-auto pb-1"><div className="relative min-w-[410px]"><div className="absolute left-[8.33%] right-[8.33%] top-2 h-1 rounded-full bg-stone-200"/><div className="absolute left-[8.33%] top-2 h-1 rounded-full bg-brand-500" style={{width:`${progress*0.8333}%`}}/><div className="relative grid grid-cols-6">{lifecycle.map((step,index)=><div key={step} className="flex flex-col items-center text-center"><span className={`grid h-5 w-5 place-items-center rounded-full border-4 ${index<=current?'border-brand-500 bg-white':'border-stone-200 bg-white'}`}/><span className={`mt-2 text-[10px] font-bold leading-tight ${index<=current?'text-brand-700':'text-stone-400'}`}>{milestones[step]}</span></div>)}</div></div></div>}</article>;
}
