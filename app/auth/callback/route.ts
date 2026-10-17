import { NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
export async function GET(request: Request) { const url = new URL(request.url); const code = url.searchParams.get('code'); const next = url.searchParams.get('next') ?? '/'; if (code) { const jar = cookies(); const supabase = createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, { cookies: { getAll: () => jar.getAll(), setAll: (items: { name: string; value: string; options?: Record<string, unknown> }[]) => items.forEach(({ name, value, options }) => jar.set(name, value, options)) } }); await supabase.auth.exchangeCodeForSession(code); } return NextResponse.redirect(new URL(next, url.origin)); }
