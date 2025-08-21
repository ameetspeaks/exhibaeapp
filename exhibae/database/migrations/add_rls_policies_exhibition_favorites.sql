-- Enable RLS (Row Level Security) for exhibition_favorites table
ALTER TABLE public.exhibition_favorites ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for exhibition_favorites
CREATE POLICY "Users can view their own exhibition favorites"
  ON public.exhibition_favorites
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own exhibition favorites"
  ON public.exhibition_favorites
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own exhibition favorites"
  ON public.exhibition_favorites
  FOR DELETE
  USING (auth.uid() = user_id);
