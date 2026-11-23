import { createClient } from '@supabase/supabase-js';
const url = import.meta.env.VITE_SUPABASE_URL;
const key = import.meta.env.VITE_SUPABASE_ANON_KEY;
export const isConfigured = Boolean(url && key && url.startsWith('https://'));
export const supabase = isConfigured ? createClient(url, key) : null;
export const CATEGORIES = ['CNC Machining','Sheet Metal','Injection Molding','3D Printing','Electronics / PCB','Casting & Forging','Plastics & Rubber','Textiles','Packaging','Industrial Equipment','Other'];
export const DEMO_REQUESTS = [
 {id:'demo-1',title:'Custom anodized aluminum enclosure for sensor module',category:'CNC Machining',quantity:500,unit:'pieces',budget_min:4500,budget_max:8000,currency:'USD',location:'United States',deadline:'2027-02-12',description:'Seeking a CNC shop to machine and anodize 6061-T6 aluminum enclosures. Tolerance ±0.1 mm on mating surfaces. Prototype and small-batch production capability preferred.',status:'open',created_at:'2026-11-20',companies:{name:'Northline Robotics'},is_demo:true},
 {id:'demo-2',title:'Food-grade silicone gaskets for dispenser assembly',category:'Plastics & Rubber',quantity:12000,unit:'pieces',budget_min:1800,budget_max:4000,currency:'USD',location:'Europe',deadline:'2027-01-28',description:'Custom molded silicone gasket, food-contact compliant, Shore A 50. Manufacturer must provide material certificates and samples before production.',status:'open',created_at:'2026-11-18',companies:{name:'Veridian Foods'},is_demo:true},
 {id:'demo-3',title:'Prototype PCB assembly with SMT components',category:'Electronics / PCB',quantity:150,unit:'boards',budget_min:2000,budget_max:6000,currency:'USD',location:'Worldwide',deadline:'2027-03-01',description:'Need prototype PCBA for embedded control board. Gerbers, BOM and pick-and-place documentation available after NDA. Functional testing requested.',status:'open',created_at:'2026-11-16',companies:{name:'Aster Devices'},is_demo:true},
 {id:'demo-4',title:'Precision stainless steel brackets for medical equipment',category:'Sheet Metal',quantity:2500,unit:'pieces',budget_min:7000,budget_max:15000,currency:'USD',location:'North America',deadline:'2027-02-25',description:'316 stainless steel formed and laser-cut brackets. Deburred finish, lot traceability and inspection documentation required.',status:'open',created_at:'2026-11-14',companies:{name:'Orion Systems'},is_demo:true}
];
export const money = (n) => n == null ? 'Open budget' : new Intl.NumberFormat('en-US',{style:'currency',currency:'USD',maximumFractionDigits:0}).format(Number(n));
export const formatDate = (d) => d ? new Date(d + (d.length===10?'T12:00:00':'')).toLocaleDateString('en-US',{month:'short',day:'numeric',year:'numeric'}) : 'Flexible';
export const short = (s,n=130) => s?.length>n ? s.slice(0,n-1).trimEnd()+'…' : s;
