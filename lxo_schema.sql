-- ===================================================
-- LX Studio - Supabase Database Schema
-- Version: 1.0
-- Description: Complete schema for LXO automation platform
-- ===================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===================================================
-- CONTACTS & LEADS
-- ===================================================

CREATE TABLE IF NOT EXISTS contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    company TEXT,
    language TEXT DEFAULT 'fr',
    canton TEXT,
    city TEXT,
    country TEXT DEFAULT 'CH',
    source TEXT, -- 'email', 'voice', 'web', 'prospect'
    tags TEXT[], -- Array of tags
    opted_out BOOLEAN DEFAULT FALSE,
    opted_out_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_contacts_email ON contacts(email);
CREATE INDEX idx_contacts_canton ON contacts(canton);
CREATE INDEX idx_contacts_opted_out ON contacts(opted_out);

CREATE TABLE IF NOT EXISTS leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contact_id UUID REFERENCES contacts(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'new', -- 'new', 'contacted', 'qualified', 'quoted', 'converted', 'lost'
    priority TEXT DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
    service_type TEXT, -- 'website', 'ecommerce', 'custom', 'maintenance', 'seo', 'automation'
    project_description TEXT,
    budget_range TEXT,
    timeline TEXT,
    score INTEGER DEFAULT 0, -- Lead scoring 0-100
    assigned_to TEXT,
    converted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_leads_contact_id ON leads(contact_id);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_score ON leads(score DESC);

-- ===================================================
-- QUOTES & INVOICES (Stripe)
-- ===================================================

CREATE TABLE IF NOT EXISTS quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,
    stripe_quote_id TEXT UNIQUE,
    quote_number TEXT UNIQUE,
    amount_chf DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'CHF',
    status TEXT DEFAULT 'draft', -- 'draft', 'sent', 'accepted', 'declined', 'expired'
    pdf_url TEXT,
    accept_url TEXT,
    expires_at TIMESTAMPTZ,
    accepted_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_quotes_lead_id ON quotes(lead_id);
CREATE INDEX idx_quotes_stripe_quote_id ON quotes(stripe_quote_id);
CREATE INDEX idx_quotes_status ON quotes(status);

CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_id UUID REFERENCES quotes(id) ON DELETE SET NULL,
    stripe_invoice_id TEXT UNIQUE,
    invoice_number TEXT UNIQUE,
    amount_chf DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'CHF',
    status TEXT DEFAULT 'draft', -- 'draft', 'open', 'paid', 'void', 'uncollectible'
    payment_url TEXT,
    paid_at TIMESTAMPTZ,
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_invoices_quote_id ON invoices(quote_id);
CREATE INDEX idx_invoices_stripe_invoice_id ON invoices(stripe_invoice_id);
CREATE INDEX idx_invoices_status ON invoices(status);

-- ===================================================
-- BLOG & CONTENT
-- ===================================================

CREATE TABLE IF NOT EXISTS blog_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wp_post_id INTEGER UNIQUE,
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    language TEXT DEFAULT 'fr',
    seo_keywords TEXT[],
    featured_image_url TEXT,
    status TEXT DEFAULT 'draft', -- 'draft', 'published', 'scheduled'
    published_at TIMESTAMPTZ,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_blog_posts_wp_post_id ON blog_posts(wp_post_id);
CREATE INDEX idx_blog_posts_slug ON blog_posts(slug);
CREATE INDEX idx_blog_posts_status ON blog_posts(status);
CREATE INDEX idx_blog_posts_published_at ON blog_posts(published_at DESC);

-- ===================================================
-- SOCIAL MEDIA
-- ===================================================

CREATE TABLE IF NOT EXISTS social_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blog_post_id UUID REFERENCES blog_posts(id) ON DELETE SET NULL,
    platform TEXT NOT NULL, -- 'linkedin', 'facebook', 'instagram', 'twitter', 'youtube'
    platform_post_id TEXT,
    content TEXT NOT NULL,
    media_url TEXT,
    hashtags TEXT[],
    status TEXT DEFAULT 'draft', -- 'draft', 'scheduled', 'published', 'failed'
    scheduled_for TIMESTAMPTZ,
    published_at TIMESTAMPTZ,
    engagement_count INTEGER DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_social_posts_blog_post_id ON social_posts(blog_post_id);
CREATE INDEX idx_social_posts_platform ON social_posts(platform);
CREATE INDEX idx_social_posts_status ON social_posts(status);
CREATE INDEX idx_social_posts_scheduled_for ON social_posts(scheduled_for);

-- ===================================================
-- PROSPECTING & CAMPAIGNS
-- ===================================================

CREATE TABLE IF NOT EXISTS prospect_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    segment TEXT, -- 'romandie', 'ticino', 'all_ch', 'custom'
    status TEXT DEFAULT 'draft', -- 'draft', 'active', 'paused', 'completed'
    daily_limit INTEGER DEFAULT 50,
    sent_count INTEGER DEFAULT 0,
    opened_count INTEGER DEFAULT 0,
    replied_count INTEGER DEFAULT 0,
    unsubscribed_count INTEGER DEFAULT 0,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_prospect_campaigns_status ON prospect_campaigns(status);

CREATE TABLE IF NOT EXISTS prospect_emails (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID REFERENCES prospect_campaigns(id) ON DELETE CASCADE,
    contact_id UUID REFERENCES contacts(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    status TEXT DEFAULT 'pending', -- 'pending', 'sent', 'opened', 'clicked', 'replied', 'bounced', 'failed'
    sent_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    replied_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(campaign_id, contact_id)
);

CREATE INDEX idx_prospect_emails_campaign_id ON prospect_emails(campaign_id);
CREATE INDEX idx_prospect_emails_contact_id ON prospect_emails(contact_id);
CREATE INDEX idx_prospect_emails_status ON prospect_emails(status);

-- ===================================================
-- REQUESTS & EVENTS
-- ===================================================

CREATE TABLE IF NOT EXISTS requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
    lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,
    kind TEXT NOT NULL, -- 'email', 'voice', 'web', 'social'
    subject TEXT,
    message TEXT,
    raw_data JSONB,
    status TEXT DEFAULT 'new', -- 'new', 'processing', 'completed', 'error'
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_requests_contact_id ON requests(contact_id);
CREATE INDEX idx_requests_lead_id ON requests(lead_id);
CREATE INDEX idx_requests_kind ON requests(kind);
CREATE INDEX idx_requests_status ON requests(status);
CREATE INDEX idx_requests_created_at ON requests(created_at DESC);

CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_hash TEXT UNIQUE NOT NULL, -- Idempotence key
    kind TEXT NOT NULL, -- 'email', 'voice', 'blog', 'social', 'prospect', 'stripe'
    entity_type TEXT, -- 'contact', 'lead', 'quote', 'invoice', 'blog_post', 'social_post'
    entity_id UUID,
    workflow_name TEXT,
    execution_id TEXT,
    payload JSONB,
    status TEXT DEFAULT 'pending', -- 'pending', 'processing', 'success', 'error'
    error_message TEXT,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_events_event_hash ON events(event_hash);
CREATE INDEX idx_events_kind ON events(kind);
CREATE INDEX idx_events_entity_type ON events(entity_type);
CREATE INDEX idx_events_entity_id ON events(entity_id);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_created_at ON events(created_at DESC);

-- ===================================================
-- ERRORS & LOGS
-- ===================================================

CREATE TABLE IF NOT EXISTS errors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_name TEXT NOT NULL,
    execution_id TEXT,
    node_name TEXT,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    input_data JSONB,
    severity TEXT DEFAULT 'error', -- 'warning', 'error', 'critical'
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_errors_workflow_name ON errors(workflow_name);
CREATE INDEX idx_errors_severity ON errors(severity);
CREATE INDEX idx_errors_resolved ON errors(resolved);
CREATE INDEX idx_errors_created_at ON errors(created_at DESC);

-- ===================================================
-- VOICE CALLS
-- ===================================================

CREATE TABLE IF NOT EXISTS voice_calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
    twilio_call_sid TEXT UNIQUE,
    phone_from TEXT,
    phone_to TEXT,
    direction TEXT, -- 'inbound', 'outbound'
    status TEXT, -- 'queued', 'ringing', 'in-progress', 'completed', 'busy', 'no-answer', 'failed'
    duration INTEGER, -- seconds
    transcript TEXT,
    intent TEXT,
    summary TEXT,
    recording_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_voice_calls_contact_id ON voice_calls(contact_id);
CREATE INDEX idx_voice_calls_twilio_call_sid ON voice_calls(twilio_call_sid);
CREATE INDEX idx_voice_calls_created_at ON voice_calls(created_at DESC);

-- ===================================================
-- FUNCTIONS & TRIGGERS
-- ===================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables with updated_at column
CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quotes_updated_at BEFORE UPDATE ON quotes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blog_posts_updated_at BEFORE UPDATE ON blog_posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_social_posts_updated_at BEFORE UPDATE ON social_posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prospect_campaigns_updated_at BEFORE UPDATE ON prospect_campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prospect_emails_updated_at BEFORE UPDATE ON prospect_emails
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_requests_updated_at BEFORE UPDATE ON requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_voice_calls_updated_at BEFORE UPDATE ON voice_calls
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===================================================
-- ROW LEVEL SECURITY (RLS)
-- ===================================================

-- Enable RLS on all tables (configure policies based on your auth setup)
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE prospect_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE prospect_emails ENABLE ROW LEVEL SECURITY;
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE errors ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_calls ENABLE ROW LEVEL SECURITY;

-- Example policy: Allow service role full access
-- Adjust these policies based on your Supabase auth configuration
CREATE POLICY "Allow service role full access" ON contacts
    FOR ALL USING (true);

CREATE POLICY "Allow service role full access" ON leads
    FOR ALL USING (true);

CREATE POLICY "Allow service role full access" ON quotes
    FOR ALL USING (true);

CREATE POLICY "Allow service role full access" ON invoices
    FOR ALL USING (true);

CREATE POLICY "Allow service role full access" ON blog_posts
    FOR ALL USING (true);

CREATE POLICY "Allow service role full access" ON social_posts
    FOR ALL USING (true);

CREATE POLICY "Allow service role full access" ON prospect_campaigns
    FOR ALL USING (true);

CREATE POLICY "Allow service role full access" ON prospect_emails
    FOR ALL USING (true);

CREATE POLICY "Allow service role full access" ON requests
    FOR ALL USING (true);

CREATE POLICY "Allow service role full access" ON events
    FOR ALL USING (true);

CREATE POLICY "Allow service role full access" ON errors
    FOR ALL USING (true);

CREATE POLICY "Allow service role full access" ON voice_calls
    FOR ALL USING (true);

-- ===================================================
-- VIEWS
-- ===================================================

-- View: Active leads with contact info
CREATE OR REPLACE VIEW v_active_leads AS
SELECT
    l.id as lead_id,
    l.status,
    l.priority,
    l.service_type,
    l.score,
    c.email,
    c.first_name,
    c.last_name,
    c.company,
    c.canton,
    l.created_at,
    l.updated_at
FROM leads l
JOIN contacts c ON l.contact_id = c.id
WHERE l.status NOT IN ('converted', 'lost');

-- View: Prospecting stats
CREATE OR REPLACE VIEW v_prospect_stats AS
SELECT
    pc.id as campaign_id,
    pc.name as campaign_name,
    pc.status,
    COUNT(pe.id) as total_sent,
    COUNT(CASE WHEN pe.status = 'opened' THEN 1 END) as opened,
    COUNT(CASE WHEN pe.status = 'replied' THEN 1 END) as replied,
    ROUND(COUNT(CASE WHEN pe.status = 'opened' THEN 1 END)::NUMERIC / NULLIF(COUNT(pe.id), 0) * 100, 2) as open_rate,
    ROUND(COUNT(CASE WHEN pe.status = 'replied' THEN 1 END)::NUMERIC / NULLIF(COUNT(pe.id), 0) * 100, 2) as reply_rate
FROM prospect_campaigns pc
LEFT JOIN prospect_emails pe ON pc.id = pe.campaign_id
WHERE pe.status = 'sent'
GROUP BY pc.id, pc.name, pc.status;

-- ===================================================
-- END OF SCHEMA
-- ===================================================
