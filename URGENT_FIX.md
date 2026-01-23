# 🚨 URGENT FIX - RUN THIS NOW!

## THE PROBLEM:
Your profiles table has **NULL names**! That's why you see "Unknown User".

## THE FIX:
Copy and paste this **ONE COMMAND** into Supabase SQL Editor:

```sql
UPDATE profiles SET name = SPLIT_PART(email, '@', 1), updated_at = NOW() WHERE name IS NULL OR name = '';
```

## WHAT IT DOES:
- Takes the email: `karthikasuresh.v2@gmail.com`
- Extracts the name: `karthikasuresh.v2`
- Sets it as the profile name

## STEP BY STEP:

### 1. Open Supabase SQL Editor
- Go to: https://supabase.com/dashboard/project/yewsmbnnizomoedmbzhh/sql/new

### 2. Paste This ONE Line:
```sql
UPDATE profiles SET name = SPLIT_PART(email, '@', 1), updated_at = NOW() WHERE name IS NULL OR name = '';
```

### 3. Click "Run" (or press Ctrl+Enter)

### 4. You Should See:
```
UPDATE 7
```
(This means 7 profiles were updated)

### 5. Verify It Worked:
Run this to check:
```sql
SELECT id, name, email FROM profiles;
```

You should see names like:
- `karthikasuresh.v2`
- `geochronous0022`
- `kiran`
- `siddhubhai998`
- etc.

### 6. Hot Reload Your App
Press `r` in the terminal

---

## THEN FOR DISCOVER USERS:

After fixing names, if "Discover Users" still shows nothing, it means you're **not logged in with Supabase**.

Check the console (F12) for:
```
📱 Using Supabase user ID: ...
```

If you see:
```
🔧 Using PHP user ID: 6852
```

Then you need to **log out and log back in with Supabase authentication**.

---

**RUN THE UPDATE COMMAND NOW!** 🚀
