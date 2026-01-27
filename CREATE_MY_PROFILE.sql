-- ============================================
-- CREATE SUPABASE PROFILE FOR PHP USER
-- ============================================

-- This will create a Supabase profile for your PHP account
-- so you can use the follow system

-- Step 1: Check your current PHP user ID
-- Run this in browser console: localStorage.getItem('user_id')
-- Let's say it returns "6852"

-- Step 2: Check if you already have a Supabase auth account
SELECT 
    id,
    email,
    created_at
FROM auth.users
WHERE email LIKE '%karthika%'
   OR email LIKE '%suresh%';

-- Step 3: If you have a Supabase auth account, check if profile exists
SELECT 
    id,
    name,
    email
FROM profiles
WHERE email LIKE '%karthika%'
   OR email LIKE '%suresh%';

-- Step 4: If profile is missing, create it
-- Replace the UUID below with your actual auth.users ID from Step 2
INSERT INTO profiles (
    id,
    email,
    name,
    created_at,
    updated_at
)
SELECT 
    id,
    email,
    COALESCE(
        raw_user_meta_data->>'name',
        SPLIT_PART(email, '@', 1)
    ) as name,
    created_at,
    NOW()
FROM auth.users
WHERE email LIKE '%karthika%'
   OR email LIKE '%suresh%'
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();

-- Step 5: Verify it was created
SELECT 
    id,
    name,
    email,
    'YOUR PROFILE' as note
FROM profiles
WHERE email LIKE '%karthika%'
   OR email LIKE '%suresh%';

-- ============================================
-- ALTERNATIVE: Create profiles for ALL auth users
-- ============================================

-- This will create profiles for EVERYONE who has a Supabase auth account
INSERT INTO profiles (id, email, name, created_at, updated_at)
SELECT 
    id,
    email,
    COALESCE(
        raw_user_meta_data->>'name',
        raw_user_meta_data->>'full_name',
        SPLIT_PART(email, '@', 1)
    ) as name,
    created_at,
    NOW()
FROM auth.users
WHERE id NOT IN (SELECT id FROM profiles)
ON CONFLICT (id) DO NOTHING;

-- Check results
SELECT COUNT(*) as total_profiles FROM profiles;
SELECT id, name, email FROM profiles ORDER BY created_at DESC LIMIT 10;
