-- Migration 018: Add Event Templates Support (Hybrid JSONB Approach)
-- Issue: #67 - Templates: Framework
-- Sprint: 4 (Week 7 - February 6, 2026)

-- Add JSONB column for flexible template data
-- Templates store: type, configuration, tasks/dishes as JSONB arrays
ALTER TABLE events
ADD COLUMN template_data JSONB DEFAULT '{}'::jsonb;

-- Add GIN index for JSONB queries (for future template marketplace queries)
CREATE INDEX idx_events_template_data ON events USING GIN (template_data);

-- Add comment explaining hybrid approach
COMMENT ON COLUMN events.template_data IS
  'Template configuration and data stored as JSONB for flexibility. '
  'Built-in templates (surprise_party, potluck) use factory pattern for type safety. '
  'Structure: {"type": "surprise_party", "guestOfHonorId": "uuid", "tasks": [...], ...} '
  'Future: User-generated templates (v1.1+) will extend this with custom_ prefix.';

-- No separate tables needed:
-- - Tasks stored in template_data->'tasks' JSONB array
-- - Dishes stored in template_data->'dishes' JSONB array
-- - Member exclusions stored in template_data->'inOnItUserIds' JSONB array

-- RLS: Inherits from events table policies (no new policies needed)
-- Privacy is enforced at the events level, template_data is just configuration
