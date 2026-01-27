-- ============================================
-- SUPABASE FOLLOW SYSTEM SETUP
-- Run this in Supabase SQL Editor
-- ============================================

-- Create follows table
CREATE TABLE IF NOT EXISTS public.follows (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    
    -- Ensure a user can't follow the same person twice
    UNIQUE(follower_id, following_id),
    
    -- Ensure a user can't follow themselves
    CHECK (follower_id != following_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows(following_id);
CREATE INDEX IF NOT EXISTS idx_follows_created_at ON public.follows(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

-- RLS Policies for follows table

-- Anyone can view follows
CREATE POLICY "Anyone can view follows"
ON public.follows FOR SELECT
USING (true);

-- Users can follow others
CREATE POLICY "Users can follow others"
ON public.follows FOR INSERT
WITH CHECK (auth.uid() = follower_id);

-- Users can unfollow
CREATE POLICY "Users can unfollow"
ON public.follows FOR DELETE
USING (auth.uid() = follower_id);

-- Create helper functions

-- Function to get follower count
CREATE OR REPLACE FUNCTION get_follower_count(user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM public.follows WHERE following_id = user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get following count
CREATE OR REPLACE FUNCTION get_following_count(user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM public.follows WHERE follower_id = user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user A follows user B
CREATE OR REPLACE FUNCTION is_following(follower UUID, following UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.follows 
        WHERE follower_id = follower AND following_id = following
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add follower/following counts to profiles view (optional but useful)
CREATE OR REPLACE VIEW profiles_with_counts AS
SELECT 
    p.*,
    (SELECT COUNT(*) FROM public.follows WHERE following_id = p.id) as followers_count,
    (SELECT COUNT(*) FROM public.follows WHERE follower_id = p.id) as following_count
FROM public.profiles p;

-- Grant permissions
GRANT SELECT ON profiles_with_counts TO authenticated;
GRANT SELECT ON profiles_with_counts TO anon;

COMMENT ON TABLE public.follows IS 'Stores follower/following relationships between users';
COMMENT ON COLUMN public.follows.follower_id IS 'User who is following';
COMMENT ON COLUMN public.follows.following_id IS 'User who is being followed';
