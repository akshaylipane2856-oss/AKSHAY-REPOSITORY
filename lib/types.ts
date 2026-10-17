export type Role = 'CUSTOMER' | 'DELIVERY_BOY' | 'ADMIN';
export type OrderStatus = 'PLACED' | 'ACCEPTED' | 'PREPARING' | 'READY_FOR_PICKUP' | 'OUT_FOR_DELIVERY' | 'DELIVERED' | 'CANCELLED';
export type Product = { id: string; name: string; description: string | null; price: number; image_url: string | null; category: string; is_available: boolean };
export type CartItem = Product & { quantity: number; unit?: 'KG' | 'PIECE' };
export const lifecycle: OrderStatus[] = ['PLACED','ACCEPTED','PREPARING','READY_FOR_PICKUP','OUT_FOR_DELIVERY','DELIVERED'];
