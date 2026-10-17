'use client';
import { LogIn, LogOut, UserRound } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
export function AuthButton() {
  const [signedIn, setSignedIn] = useState(false); const [open, setOpen] = useState(false); const [name,setName]=useState(''); const menuRef=useRef<HTMLDivElement>(null);
  useEffect(() => { const applyUser=(user:{user_metadata?:Record<string,unknown>;email?:string}|null)=>{setSignedIn(!!user);setName(String(user?.user_metadata?.full_name||user?.user_metadata?.name||user?.email?.split('@')[0]||''));};const supabase=createClient(); supabase.auth.getUser().then(({data})=>applyUser(data.user)); const {data:{subscription}}=supabase.auth.onAuthStateChange((_event,session)=>applyUser(session?.user||null)); return ()=>subscription.unsubscribe(); }, []);
  useEffect(()=>{const close=(event:PointerEvent)=>{if(menuRef.current&&!menuRef.current.contains(event.target as Node))setOpen(false);};document.addEventListener('pointerdown',close);return()=>document.removeEventListener('pointerdown',close);},[]);
  const signIn = async () => { const supabase = createClient(); await supabase.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: `${location.origin}/auth/callback` } }); };
  const signOut = async () => { await createClient().auth.signOut(); location.href='/'; };
  if (signedIn) return <div ref={menuRef} className="relative"><button aria-label="Account menu" onClick={()=>setOpen(!open)} className="flex h-10 items-center gap-2 rounded-full bg-brand-50 px-2 text-brand-700 ring-1 ring-brand-100"><span className="grid h-7 w-7 place-items-center rounded-full bg-brand-100"><UserRound size={16}/></span><span className="hidden max-w-24 truncate text-sm font-bold sm:block">{name||'My profile'}</span></button>{open&&<div className="absolute right-0 mt-2 w-44 overflow-hidden rounded-xl bg-white py-1 shadow-lg ring-1 ring-black/5"><p className="truncate px-4 py-2 text-xs font-bold text-stone-400">{name||'Signed in'}</p><a href="/orders" onClick={()=>setOpen(false)} className="block px-4 py-2.5 text-sm font-semibold hover:bg-brand-50">My orders</a><button onClick={signOut} className="flex w-full items-center gap-2 px-4 py-2.5 text-sm font-semibold text-brand-700 hover:bg-brand-50"><LogOut size={16}/>Sign out</button></div>}</div>;
  return <button onClick={signIn} className="btn-secondary !rounded-full !px-3 !py-2 text-sm"><LogIn size={16}/><span className="hidden sm:inline">Sign in</span><UserRound className="sm:hidden" size={17}/></button>;
}
