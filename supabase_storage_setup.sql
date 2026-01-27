-- =====================================================
-- SUPABASE STORAGE BUCKETS SETUP
-- Run these commands in your Supabase SQL Editor
-- =====================================================

-- 1. Create 'post_images' bucket for post images
INSERT INTO storage.buckets (id, name, public)
VALUES ('post_images', 'post_images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Create 'avatars' bucket for profile avatars
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Set up storage policies for post_images bucket
-- Allow anyone to read
CREATE POLICY "Public Access for post_images"
ON storage.objects FOR SELECT
USING (bucket_id = 'post_images');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload post_images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'post_images' AND auth.role() = 'authenticated');

-- Allow users to update their own uploads
CREATE POLICY "Users can update their own post_images"
ON storage.objects FOR UPDATE
USING (bucket_id = 'post_images' AND auth.role() = 'authenticated');

-- Allow users to delete their own uploads
CREATE POLICY "Users can delete their own post_images"
ON storage.objects FOR DELETE
USING (bucket_id = 'post_images' AND auth.role() = 'authenticated');

-- 4. Set up storage policies for avatars bucket
-- Allow anyone to read
CREATE POLICY "Public Access for avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Allow users to update their own avatars
CREATE POLICY "Users can update their own avatars"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Allow users to delete their own avatars
CREATE POLICY "Users can delete their own avatars"
ON storage.objects FOR DELETE
USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check if buckets were created successfully
SELECT * FROM storage.buckets;

-- Check if policies were created successfully
SELECT * FROM pg_policies WHERE schemaname = 'storage';
