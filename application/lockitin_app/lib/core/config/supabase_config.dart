// Supabase Configuration
//
// This file contains the Supabase URL and Anonymous Key for connecting to your backend.
//
// ⚠️ IMPORTANT: Replace these with your actual Supabase credentials
//
// To get your credentials:
// 1. Go to https://app.supabase.com/
// 2. Select your project
// 3. Go to Settings > API
// 4. Copy the "Project URL" and "anon public" key

class SupabaseConfig {
  /// Your Supabase project URL
  /// Format: https://your-project-id.supabase.co
  static const String supabaseUrl = 'https://pcesejdaknymvckrtgdk.supabase.co';

  /// Your Supabase anonymous/public key
  /// This key is safe to use in client-side code
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjZXNlamRha255bXZja3J0Z2RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyMzA0MDgsImV4cCI6MjA4MDgwNjQwOH0.cjwFa3oTy0bUVaCOpOnAhviLBYGMZBECK-XNw1mGrGk';

  /// Whether to enable debug logging for Supabase
  static const bool enableDebugLogging = true;
}
