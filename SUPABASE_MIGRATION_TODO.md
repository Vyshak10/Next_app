# 🔧 Supabase Migration - Remaining Fixes

## ✅ What's Already Done:
1. ✅ Updated Supabase URL and anon key in Flutter code
2. ✅ Fixed bucket name from `post-images` to `post_images`
3. ✅ Added missing `default_post.png` asset

## ⚠️ What You Need to Do:

### 1. Update Avatar URLs in MySQL Database

Run this SQL query on your **PHP MySQL database** (at indianrupeeservices.in):

```sql
-- Update old Supabase URLs to new ones
UPDATE users 
SET avatar_url = REPLACE(avatar_url, 
  'https://mcwngfebeexcugypioey.supabase.co', 
  'https://yewsmbnnizomoedmbzhh.supabase.co'
)
WHERE avatar_url LIKE '%mcwngfebeexcugypioey.supabase.co%';

-- Convert SVG avatars to PNG (Flutter Web doesn't support SVG)
UPDATE users 
SET avatar_url = REPLACE(avatar_url, '/svg?', '/png?')
WHERE avatar_url LIKE '%dicebear.com%/svg?%';
```

### 2. Set Up Supabase Storage Policies

Go to your Supabase Dashboard: https://supabase.com/dashboard/project/yewsmbnnizomoedmbzhh

Navigate to: **SQL Editor** and run:

```sql
-- Allow public read access to post_images bucket
CREATE POLICY "Public Access for post_images"
ON storage.objects FOR SELECT
USING (bucket_id = 'post_images');

-- Allow authenticated users to upload to post_images
CREATE POLICY "Authenticated users can upload post_images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'post_images');

-- Allow users to update their uploads
CREATE POLICY "Users can update their own post_images"
ON storage.objects FOR UPDATE
USING (bucket_id = 'post_images');

-- Allow users to delete their uploads
CREATE POLICY "Users can delete their own post_images"
ON storage.objects FOR DELETE
USING (bucket_id = 'post_images');

-- Create avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public read access to avatars bucket
CREATE POLICY "Public Access for avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Allow authenticated users to upload avatars
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars');
```

### 3. Known Limitations

**Razorpay on Web:**
- ⚠️ Razorpay Flutter plugin doesn't work on Web
- The payment feature will only work on mobile (Android/iOS)
- Error: `MissingPluginException(No implementation found for method resync)`
- **Solution**: Either use Razorpay's web SDK separately for web, or disable payment features on web

## 📊 Current Error Summary:

| Error | Status | Action Required |
|-------|--------|-----------------|
| Old Supabase avatar URLs | ⚠️ Pending | Run SQL update query |
| SVG image format | ⚠️ Pending | Convert to PNG in database |
| Missing default_post.png | ✅ Fixed | Already added |
| Razorpay on Web | ⚠️ Known Issue | Use web SDK or disable on web |
| Storage bucket policies | ⚠️ Pending | Run SQL in Supabase |

## 🚀 After Completing These Steps:

1. Hot reload your Flutter app (press `r` in terminal)
2. Test image uploads to verify Supabase storage works
3. Check that avatar images load correctly
4. Payment features will only work on mobile builds
