-- ============================================
-- STEP 1: DIAGNOSE THE PROBLEM
-- ============================================

-- Check how many users exist in auth.users
SELECT 'Total auth users:' as info, COUNT(*) as count FROM auth.users;

-- Check how many profiles exist
SELECT 'Total profiles:' as info, COUNT(*) as count FROM profiles;

-- Check profiles with NULL names
SELECT 'Profiles with NULL names:' as info, COUNT(*) as count 
FROM profiles 
WHERE name IS NULL OR name = '';

-- Show all profiles (to see what data exists)
SELECT 
    id,
    name,
    email,
    role,
    user_type,
    created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 10;

-- Show auth users that DON'T have profiles
SELECT 
    'Auth users WITHOUT profiles:' as info,
    COUNT(*) as count
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = au.id
);

-- ============================================
-- STEP 2: FIX THE PROBLEM
-- ============================================

-- Create profiles for auth users that don't have them
INSERT INTO profiles (
    id,
    email,
    name,
    created_at,
    updated_at
)
SELECT 
    au.id,
    au.email,
    COALESCE(
        au.raw_user_meta_data->>'name',
        au.raw_user_meta_data->>'full_name',
        SPLIT_PART(au.email, '@', 1)
    ) as name,
    au.created_at,
    NOW()
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = au.id
);

-- Update profiles that have NULL or empty names
UPDATE profiles
SET 
    name = COALESCE(
        name,
        SPLIT_PART(email, '@', 1),
        'User'
    ),
    updated_at = NOW()
WHERE name IS NULL OR name = '';

-- ============================================
-- STEP 3: VERIFY THE FIX
-- ============================================

-- Check the results
SELECT 'After fix - Total profiles:' as info, COUNT(*) as count FROM profiles;

SELECT 'After fix - Profiles with names:' as info, COUNT(*) as count 
FROM profiles 
WHERE name IS NOT NULL AND name != '';

-- Show all profiles now
SELECT 
    id,
    name,
    email,
    role,
    user_type,
    created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 20;

-- ============================================
-- STEP 4: ADD SOME TEST DATA (OPTIONAL)
-- ============================================

-- If you want to add test users for testing the follow system,
-- uncomment and run this section:

/*
-- Insert test user 1
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at
)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'test1@example.com',
    crypt('password123', gen_salt('bf')),
    NOW(),
    '{"name": "John Doe"}'::jsonb,
    NOW(),
    NOW()
)
ON CONFLICT (email) DO NOTHING
RETURNING id;

-- Then create profile for test user 1
-- (Replace the UUID below with the one returned above)
INSERT INTO profiles (id, email, name, role, user_type)
VALUES (
    'PASTE_UUID_HERE',
    'test1@example.com',
    'John Doe',
    'Software Engineer',
    'startup'
);
*/
