-- Create exhibition_attendees table for tracking who is attending exhibitions
CREATE TABLE IF NOT EXISTS exhibition_attendees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    exhibition_id UUID REFERENCES exhibitions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, exhibition_id)
);

-- Create brand_favorites table for tracking favorite brands
CREATE TABLE IF NOT EXISTS brand_favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    brand_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, brand_id)
);

-- Add RLS policies for exhibition_attendees
ALTER TABLE exhibition_attendees ENABLE ROW LEVEL SECURITY;

-- Users can view their own attendance records
CREATE POLICY "Users can view their own attendance" ON exhibition_attendees
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own attendance records
CREATE POLICY "Users can insert their own attendance" ON exhibition_attendees
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can delete their own attendance records
CREATE POLICY "Users can delete their own attendance" ON exhibition_attendees
    FOR DELETE USING (auth.uid() = user_id);

-- Add RLS policies for brand_favorites
ALTER TABLE brand_favorites ENABLE ROW LEVEL SECURITY;

-- Users can view their own brand favorites
CREATE POLICY "Users can view their own brand favorites" ON brand_favorites
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own brand favorites
CREATE POLICY "Users can insert their own brand favorites" ON brand_favorites
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can delete their own brand favorites
CREATE POLICY "Users can delete their own brand favorites" ON brand_favorites
    FOR DELETE USING (auth.uid() = user_id);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_exhibition_attendees_user_id ON exhibition_attendees(user_id);
CREATE INDEX IF NOT EXISTS idx_exhibition_attendees_exhibition_id ON exhibition_attendees(exhibition_id);
CREATE INDEX IF NOT EXISTS idx_brand_favorites_user_id ON brand_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_brand_favorites_brand_id ON brand_favorites(brand_id);
