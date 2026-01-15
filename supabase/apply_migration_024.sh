#!/bin/bash
# Script to apply migration 024 (enable realtime for events table)
# This migration is required for Potluck template real-time dish claim/unclaim updates

set -e

echo "📦 Applying migration 024: Enable Realtime for Events Table"
echo ""

# Check if migration file exists
if [ ! -f "supabase/migrations/024_enable_realtime_events.sql" ]; then
    echo "❌ Error: Migration file not found"
    exit 1
fi

echo "Migration file found: supabase/migrations/024_enable_realtime_events.sql"
echo ""

# Apply via Supabase CLI (if configured)
if command -v supabase &> /dev/null; then
    echo "🚀 Applying migration via Supabase CLI..."
    supabase db push
    echo ""
    echo "✅ Migration applied successfully"
else
    echo "⚠️  Supabase CLI not found"
    echo ""
    echo "To apply this migration manually:"
    echo "1. Go to your Supabase project dashboard"
    echo "2. Navigate to SQL Editor"
    echo "3. Run this SQL command:"
    echo ""
    echo "   ALTER PUBLICATION supabase_realtime ADD TABLE events;"
    echo ""
    echo "4. Verify it was added by running:"
    echo ""
    echo "   SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';"
    echo ""
fi

echo ""
echo "⚠️  IMPORTANT: Full app restart required!"
echo "After applying this migration, you MUST:"
echo "1. Stop the Flutter app completely (don't just hot reload)"
echo "2. Restart the app from scratch"
echo "3. WebSocket subscriptions need to reconnect to see new realtime config"
echo ""
