-- Complete fix: Set password AND verify email for karthikasuresh.v2@gmail.com
-- Run this in Supabase SQL Editor

UPDATE auth.users
SET 
  encrypted_password = crypt('Kathu@123', gen_salt('bf')),
  email_confirmed_at = NOW(),
  updated_at = NOW()
WHERE email = 'karthikasuresh.v2@gmail.com';

-- Verify it worked
SELECT 
  id, 
  email, 
  email_confirmed_at,
  created_at, 
  updated_at 
FROM auth.users 
WHERE email = 'karthikasuresh.v2@gmail.com';
