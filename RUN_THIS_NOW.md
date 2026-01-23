# 🚨 RUN THIS ONE COMMAND IN SUPABASE NOW!

Open Supabase SQL Editor and run this **ONE LINE**:

```sql
UPDATE profiles SET name = SPLIT_PART(email, '@', 1) WHERE name IS NULL OR name = '';
```

Then **hot reload** your app (press `r`).

That's it. This will fix the names and you'll see all 8 users.
