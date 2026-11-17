// Point d'entrée du bundle vendor : seul createClient est réexporté (SPEC-001.8 b, ADR-006 §2).
export { createClient } from '@supabase/supabase-js';
