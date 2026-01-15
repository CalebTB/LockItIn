-- Add template_data column to event_proposals table
-- Enables template support for proposals (Surprise Party, Potluck, etc.)

ALTER TABLE event_proposals
ADD COLUMN template_data JSONB DEFAULT '{}'::jsonb;

-- Add GIN index for fast JSONB queries
CREATE INDEX idx_event_proposals_template_data
ON event_proposals USING gin(template_data);

-- Add comment explaining the column
COMMENT ON COLUMN event_proposals.template_data IS
'Template configuration data (surprise_party, potluck, etc). Transferred to events.template_data after proposal is finalized.';
