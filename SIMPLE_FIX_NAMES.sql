-- ============================================
-- SIMPLE FIX: Add names to all profiles
-- ============================================

-- Step 1: Check current state
SELECT 
    'BEFORE UPDATE' as status,
    COUNT(*) as total_profiles,
    COUNT(name) as profiles_with_names,
    COUNT(*) - COUNT(name) as profiles_without_names
FROM profiles;

-- Step 2: Update ALL profiles to have names
UPDATE profiles
SET 
    name = CASE 
        WHEN name IS NOT NULL AND name != '' THEN name
        ELSE SPLIT_PART(email, '@', 1)
    END,
    updated_at = NOW()
WHERE name IS NULL OR name = '';

-- Step 3: Check results
SELECT 
    'AFTER UPDATE' as status,
    COUNT(*) as total_profiles,
    COUNT(name) as profiles_with_names,
    COUNT(*) - COUNT(name) as profiles_without_names
FROM profiles;

-- Step 4: Show all profiles with their names
SELECT 
    id,
    name,
    email,
    role,
    user_type
FROM profiles
ORDER BY email;

-- Step 5: Verify specific user
SELECT 
    id,
    name,
    email,
    'This is YOUR profile' as note
FROM profiles
WHERE email LIKE '%karthika%'
   OR email LIKE '%suresh%';
