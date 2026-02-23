-- Verify enums exist
SELECT typname FROM pg_type WHERE typname IN ('taxtype', 'ratetype');

-- List all tables containing 'tax'
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name LIKE '%tax%';
