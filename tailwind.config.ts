import type { Config } from 'tailwindcss';
const config: Config = { content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'], theme: { extend: { colors: { brand: { 50: '#fff4f4', 100: '#ffe5e5', 500: '#d62d2d', 600: '#ba2020', 700: '#991919', 900: '#5c1111' } }, boxShadow: { card: '0 3px 12px rgba(112, 17, 17, .08)' } } }, plugins: [] };
export default config;
