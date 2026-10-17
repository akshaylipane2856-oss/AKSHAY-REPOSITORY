'use client';

import { Menu, ShoppingBag, X } from 'lucide-react';
import { useState } from 'react';
import { AuthButton } from './auth-button';

export function SiteHeader({ cartCount, onCartOpen }: { cartCount?: number; onCartOpen?: () => void }) {
  const [mobileOpen, setMobileOpen] = useState(false);

  return <header className="sticky top-0 z-20 border-b border-brand-100/70 bg-white/95 backdrop-blur">
    <div className="shell flex h-16 items-center justify-between">
      <a href="/" aria-label="Mama Laddu home" className="flex min-w-0 items-center gap-2">
        <img src="/mama-laddu-mark.png" alt="Mama Laddu emblem" className="h-9 w-9 shrink-0 translate-x-1 -translate-y-1 object-contain sm:h-11 sm:w-11" />
        <img src="/mama-laddu-wordmark.png" alt="मामा वडेवाले स्वादिष्ट व नमकीन" className="h-9 w-auto max-w-[112px] object-contain sm:h-11 sm:max-w-[138px]" />
      </a>
      <nav className="hidden gap-6 text-sm font-semibold md:flex"><a href="/#sweets">Sweets</a><a href="/#about">Our story</a><a href="/orders">My orders</a></nav>
      <div className="flex shrink-0 items-center gap-2">
        <button aria-label="Open navigation" onClick={() => setMobileOpen(!mobileOpen)} className="grid h-10 w-10 place-items-center rounded-full border border-brand-100 text-brand-700 md:hidden">{mobileOpen ? <X size={19} /> : <Menu size={20} />}</button>
        <AuthButton />
        {onCartOpen && <button onClick={onCartOpen} aria-label="Open cart" className="relative grid h-10 w-10 place-items-center rounded-full bg-brand-500 text-white"><ShoppingBag size={19} />{cartCount! > 0 && <span className="absolute -right-1 -top-1 grid h-5 w-5 place-items-center rounded-full bg-stone-900 text-[10px] font-bold">{cartCount}</span>}</button>}
      </div>
    </div>
    {mobileOpen && <nav className="border-t border-brand-100 bg-white px-4 py-3 shadow-lg md:hidden"><div className="shell grid gap-1 px-0"><a onClick={() => setMobileOpen(false)} href="/#sweets" className="rounded-lg px-3 py-3 text-sm font-bold hover:bg-brand-50">Sweets</a><a onClick={() => setMobileOpen(false)} href="/#about" className="rounded-lg px-3 py-3 text-sm font-bold hover:bg-brand-50">Our story</a><a onClick={() => setMobileOpen(false)} href="/orders" className="rounded-lg px-3 py-3 text-sm font-bold hover:bg-brand-50">My orders</a></div></nav>}
  </header>;
}
