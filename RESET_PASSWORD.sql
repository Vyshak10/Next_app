-- Reset password for karthikasuresh.v2@gmail.com in Supabase
-- Run this in Supabase SQL Editor

-- This will set the password to: Kathu@123
UPDATE auth.users
SET 
  encrypted_password = crypt('Kathu@123', gen_salt('bf')),
  updated_at = NOW()
WHERE email = 'karthikasuresh.v2@gmail.com';

-- Verify it worked
SELECT id, email, created_at, updated_at 
FROM auth.users 
WHERE email = 'karthikasuresh.v2@gmail.com';
