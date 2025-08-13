class SupabaseConfig {
  static const String url = 'https://ulqlhjluytobqaviuswk.supabase.co';
  
  // 🚨 IMPORTANT: The key you provided is a service role key, but we need the anon key
  // 
  // To get your anon key:
  // 1. Go to: https://supabase.com/dashboard/project/ulqlhjluytobqaviuswk
  // 2. Click: Settings > API
  // 3. Under "Project API keys" look for the "anon" "public" key
  //    - Do NOT use the service_role key (which contains "role":"service_role")
  //    - The anon key should contain "role":"anon" in the JWT
  // 4. Replace the line below with your anon key
  // ⚠️ REPLACE THIS LINE with your complete anon key
  // DO NOT use the example key below - it won't work!
  // Copy the entire "anon" "public" key from your Supabase dashboard
  // 🚨 CRITICAL: You're still using the service_role key!
  // You need to use the anon key instead.
  // 
  // Steps to get the correct key:
  // 1. Go to: https://supabase.com/dashboard/project/ulqlhjluytobqaviuswk
  // 2. Click: Settings > API
  // 3. Look for "Project API keys"
  // 4. Copy the "anon" "public" key (NOT the service_role key you're currently using)
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVscWxoamx1eXRvYnFhdml1c3drIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NzA0NDQwNywiZXhwIjoyMDYyNjIwNDA3fQ.X7kChYi2U-xVAKOBaLY16Vyx1IY5DTG_SwYKan_093U';
  
  // Example of what your anon key JWT should look like:
  // eyJhbGciOiJIUzI1NiIsInR5cCI6IkpRXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVscWxoamx1eXRvYnFhdml1c3drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcwNDQ0MDcsImV4cCI6MjA2MjYyMDQwN30.XXXXX
  //                                                                                                                   ^^^^^^^^
  //                                                                                                                   Notice "role":"anon" here
}
