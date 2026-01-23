# 🔧 FIX "UNKNOWN USER" & "NO USERS FOUND" - STEP BY STEP

## 🎯 THE PROBLEM:
1. **"Unknown User"** = Your profile exists but the `name` field is NULL
2. **"No users found"** = The `profiles` table is empty or missing entries

## ✅ THE SOLUTION:

### **STEP 1: Go to Supabase Dashboard**
1. Open https://supabase.com/dashboard
2. Select your project: `yewsmbnnizomoedmbzhh`
3. Click **"SQL Editor"** in the left sidebar

### **STEP 2: Run the Fixed Script**
1. Open the file: `check_and_populate_profiles.sql`
2. **Copy ALL the contents**
3. **Paste into Supabase SQL Editor**
4. Click **"Run"** (or press Ctrl+Enter)

### **STEP 3: What You Should See**
After running, you should see results like:
```
total_profiles: 8
total_profiles_after: 8
```

And a list of profiles with:
- ✅ `id` (UUID)
- ✅ `name` (NOT NULL - extracted from email)
- ✅ `email`
- ✅ `role`

### **STEP 4: Hot Reload Your App**
1. Go back to your Flutter app
2. Press `r` in the terminal to hot reload
3. Navigate to your profile
4. Click "Discover People"

## 🎊 WHAT TO EXPECT:
- ✅ Your profile should show your name (from email, e.g., "siddhubhai998")
- ✅ "Discover People" should show all users in the profiles table
- ✅ You can follow/unfollow them

## 🔍 IF IT STILL DOESN'T WORK:

### Check 1: Are there profiles?
Run this in SQL Editor:
```sql
SELECT COUNT(*) FROM profiles;
```
Should return a number > 0

### Check 2: Do profiles have names?
Run this:
```sql
SELECT id, name, email FROM profiles WHERE name IS NOT NULL;
```
Should show profiles with names

### Check 3: Check console logs
Look for these messages in your browser console (F12):
```
✅ Loaded X users
💎 Searching Supabase for UUID: ...
```

## 📝 WHAT THE SCRIPT DOES:
1. **Creates missing profiles** from `auth.users`
2. **Extracts names** from user metadata or email
3. **Updates NULL names** with email username
4. **Shows you the results**

---

**Run the script now and let me know what you see!** 🚀
