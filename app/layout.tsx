import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'Sweet Home | Fresh sweets, delivered', description: 'Your neighbourhood sweet shop online.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
