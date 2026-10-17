export type ItemUnit = 'KG' | 'PIECE';

export const unitForCategory = (category: string): ItemUnit => category === 'Sweets' || category === 'Namkin' ? 'KG' : 'PIECE';
export const quantityStep = (category: string) => unitForCategory(category) === 'KG' ? 0.5 : 1;
export const formatQuantity = (quantity: number, unit: ItemUnit = 'KG') => unit === 'KG' ? quantity === 0.25 ? '250 g' : `${quantity} kg` : `${quantity}`;
export const priceLabel = (price: number, unit: ItemUnit) => unit === 'KG' ? `₹${price} / kg` : `₹${price}`;
export const cartBadgeCount = (items: Array<{ quantity: number; category: string }>) => items.reduce((total, item) => total + (unitForCategory(item.category) === 'KG' ? Math.max(1, Math.round(item.quantity / 0.5)) : item.quantity), 0);
