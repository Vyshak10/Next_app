# 📝 How to Update Avatar URLs in PHP/MySQL Database

## The Problem:
Your MySQL database (used by your PHP backend) still has avatar URLs pointing to the old Supabase project:
- ❌ Old: `https://mcwngfebeexcugypioey.supabase.co`
- ✅ New: `https://yewsmbnnizomoedmbzhh.supabase.co`

This causes image loading errors in your app.

---

## **Method 1: Using phpMyAdmin** (Recommended - Easiest) ⭐

### Step 1: Access phpMyAdmin
1. Go to your hosting control panel (cPanel)
2. Find and click **"phpMyAdmin"**
3. Or visit: `https://indianrupeeservices.in/phpmyadmin`
4. Log in with your database credentials

### Step 2: Select Your Database
- Click on your database name in the left sidebar
- It's probably named something like `next_db`, `nextapp_db`, or similar

### Step 3: Run SQL Queries
1. Click the **"SQL"** tab at the top
2. Copy and paste this SQL code:

```sql
-- Update old Supabase URLs to new ones in users table
UPDATE users 
SET avatar_url = REPLACE(
  avatar_url, 
  'https://mcwngfebeexcugypioey.supabase.co', 
  'https://yewsmbnnizomoedmbzhh.supabase.co'
)
WHERE avatar_url LIKE '%mcwngfebeexcugypioey.supabase.co%';

-- Convert SVG avatars to PNG (Flutter Web can't render SVG)
UPDATE users 
SET avatar_url = REPLACE(avatar_url, '/svg?', '/png?')
WHERE avatar_url LIKE '%dicebear.com%/svg?%';

-- If you have a startups table, update it too
UPDATE startups 
SET avatar_url = REPLACE(
  avatar_url, 
  'https://mcwngfebeexcugypioey.supabase.co', 
  'https://yewsmbnnizomoedmbzhh.supabase.co'
)
WHERE avatar_url LIKE '%mcwngfebeexcugypioey.supabase.co%';

UPDATE startups 
SET avatar_url = REPLACE(avatar_url, '/svg?', '/png?')
WHERE avatar_url LIKE '%dicebear.com%/svg?%';
```

3. Click **"Go"** to execute
4. You should see a success message like "X rows affected"

### Step 4: Verify
Run this query to check the results:
```sql
SELECT id, name, avatar_url 
FROM users 
WHERE avatar_url IS NOT NULL 
LIMIT 10;
```

You should see the new Supabase URL in the results.

---

## **Method 2: Using PHP Migration Script**

### Step 1: Configure the Script
1. Open the file: `migrate_avatar_urls.php` (I just created it)
2. Update these lines with your actual database credentials:
```php
$host = 'localhost';  // Usually 'localhost'
$dbname = 'your_database_name';  // Your actual database name
$username = 'your_db_username';  // Your database username
$password = 'your_db_password';  // Your database password
```

### Step 2: Upload to Server
Upload `migrate_avatar_urls.php` to:
```
https://indianrupeeservices.in/NEXT/backend/migrate_avatar_urls.php
```

### Step 3: Run the Script
1. Visit the URL in your browser:
   ```
   https://indianrupeeservices.in/NEXT/backend/migrate_avatar_urls.php
   ```
2. The script will run and show you the results
3. You should see messages like:
   ```
   ✅ Updated X old Supabase URLs
   ✅ Converted X SVG avatars to PNG
   ```

### Step 4: Delete the Script
**IMPORTANT:** After running it successfully, **delete the file from your server** for security!

---

## **Method 3: Using MySQL Command Line**

If you have SSH access to your server:

```bash
# Connect to MySQL
mysql -u your_username -p your_database_name

# Run the update queries
UPDATE users 
SET avatar_url = REPLACE(avatar_url, 'https://mcwngfebeexcugypioey.supabase.co', 'https://yewsmbnnizomoedmbzhh.supabase.co')
WHERE avatar_url LIKE '%mcwngfebeexcugypioey.supabase.co%';

UPDATE users 
SET avatar_url = REPLACE(avatar_url, '/svg?', '/png?')
WHERE avatar_url LIKE '%dicebear.com%/svg?%';

# Exit
exit;
```

---

## **What Tables to Update?**

You need to update any table that has an `avatar_url` column. Common tables:
- ✅ `users`
- ✅ `startups`
- ✅ `profiles` (if it exists)

To check which tables have avatar_url:
```sql
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE COLUMN_NAME = 'avatar_url' 
AND TABLE_SCHEMA = 'your_database_name';
```

---

## **After Updating:**

1. **Restart your Flutter app** (hot reload)
2. **Clear browser cache** (Ctrl+Shift+Delete)
3. **Check if avatar images load** without errors

---

## **Need Help?**

If you're not sure about your database credentials, check:
1. Your hosting control panel
2. Or look in your PHP backend files (like `config.php` or `database.php`)
3. The credentials are usually in a file like:
   ```
   https://indianrupeeservices.in/NEXT/backend/config.php
   ```

Let me know which method you want to use, and I can help you through it! 🚀
