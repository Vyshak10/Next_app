-- Check and populate profiles table in Supabase
-- Run this in Supabase SQL Editor

-- First, let's see what's in the profiles table
SELECT COUNT(*) as total_profiles FROM profiles;

-- Let's see the actual profiles
SELECT id, name, email, role, avatar_url FROM profiles LIMIT 10;

-- If the table is empty or has incomplete data, let's check auth.users
SELECT id, email, raw_user_meta_data FROM auth.users LIMIT 10;

-- Now let's make sure all auth users have profiles WITH NAMES
-- This will create profiles for any auth users that don't have one
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
    NOW() as updated_at
FROM auth.users
WHERE id NOT IN (SELECT id FROM profiles)
ON CONFLICT (id) DO NOTHING;

-- Update existing profiles that have NULL names
UPDATE profiles
SET 
    name = SPLIT_PART(email, '@', 1),
    updated_at = NOW()
WHERE name IS NULL OR name = '';

-- Verify the profiles were created
SELECT COUNT(*) as total_profiles_after FROM profiles;

-- Show the profiles
SELECT 
    id, 
    name, 
    email, 
    role,
    created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 20;
