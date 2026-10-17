import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: Request) {
  const { orderId } = await request.json().catch(() => ({}));
  if (typeof orderId !== 'string') return NextResponse.json({ error: 'Invalid order.' }, { status: 400 });

  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized.' }, { status: 401 });

  const { data: order, error } = await supabase
    .from('orders')
    .select('id,total_amount,profiles!orders_customer_id_fkey(full_name,phone),addresses(line1,city,pincode,phone),order_items(quantity,product_name,unit)')
    .eq('id', orderId)
    .eq('customer_id', user.id)
    .single();
  if (error || !order) return NextResponse.json({ error: 'Order not found.' }, { status: 404 });

  const token = process.env.TELEGRAM_BOT_TOKEN;
  const chatId = process.env.TELEGRAM_CHAT_ID;
  if (!token || !chatId) return NextResponse.json({ error: 'Telegram is not configured.' }, { status: 503 });

  const customer = order.profiles as unknown as { full_name: string | null; phone: string | null } | null;
  const address = order.addresses as unknown as { line1: string; city: string; pincode: string; phone: string | null } | null;
  const items = (order.order_items as unknown as { quantity: number; product_name: string; unit: 'KG' | 'PIECE' }[] | null) ?? [];
  const text = [
    '🍬 New Sweet Home order',
    `Order: #${order.id.slice(0, 8).toUpperCase()}`,
    `Customer: ${customer?.full_name || 'Customer'}`,
    `Phone: ${customer?.phone || address?.phone || 'Not provided'}`,
    `Address: ${address ? `${address.line1}, ${address.city} - ${address.pincode}` : 'Not available'}`,
    `Items: ${items.map(item => `${item.quantity}${item.unit === 'KG' ? ' kg' : ''} ${item.product_name}`).join(', ') || 'Not available'}`,
    `Total: ₹${order.total_amount}`,
  ].join('\n');

  const telegramResponse = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, text }),
    cache: 'no-store',
  });
  if (!telegramResponse.ok) return NextResponse.json({ error: 'Telegram notification failed.' }, { status: 502 });
  return NextResponse.json({ ok: true });
}
