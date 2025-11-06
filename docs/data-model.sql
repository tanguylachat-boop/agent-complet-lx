-- ============================================================================
-- LX Studio - Automation Pipeline Database Schema
-- PostgreSQL / Supabase compatible
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- COMPANIES & CONTACTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  website TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  city TEXT,
  postal_code TEXT,
  country TEXT DEFAULT 'CH',
  industry TEXT,
  size_employees TEXT,
  status TEXT DEFAULT 'prospect', -- prospect|qualified|won|lost|churned
  source TEXT, -- google_places|hunter|manual|referral
  notes TEXT,
  hash_key TEXT UNIQUE, -- dedup key (hash of name+phone+city)
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  email TEXT NOT NULL,
  phone TEXT,
  role TEXT,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_companies_status ON companies(status);
CREATE INDEX idx_companies_hash_key ON companies(hash_key);
CREATE INDEX idx_contacts_company ON contacts(company_id);

-- ============================================================================
-- AUDITS & SPECIFICATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS audits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  source TEXT, -- typeform|voice|manual
  raw_responses JSONB, -- raw data from Typeform/Voice
  structured_data JSONB, -- AI-parsed structured audit
  summary TEXT,
  pain_points TEXT[],
  opportunities TEXT[],
  manual_tasks_count INTEGER,
  manual_hours_per_week NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS specs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  audit_id UUID REFERENCES audits(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  cdc_document TEXT, -- full CDC in markdown/text
  flows JSONB, -- array of {name, description, complexity, steps[]}
  integrations TEXT[], -- list of systems to integrate
  constraints JSONB, -- technical constraints, preferences
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_audits_company ON audits(company_id);
CREATE INDEX idx_specs_audit ON specs(audit_id);
CREATE INDEX idx_specs_company ON specs(company_id);

-- ============================================================================
-- ESTIMATES & ROI
-- ============================================================================

CREATE TABLE IF NOT EXISTS estimates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  spec_id UUID REFERENCES specs(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  total_hours NUMERIC(10,2),
  hourly_rate_chf NUMERIC(10,2) DEFAULT 150,
  total_cost_chf NUMERIC(10,2),
  buffer_percent NUMERIC(5,2) DEFAULT 20,
  confidence_level TEXT, -- high|medium|low
  risks JSONB, -- [{ risk, impact, mitigation }]
  time_saved_hours_per_week NUMERIC(10,2),
  cost_saved_chf_per_year NUMERIC(10,2),
  payback_months NUMERIC(5,1),
  roi_percent NUMERIC(5,1),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_estimates_spec ON estimates(spec_id);
CREATE INDEX idx_estimates_company ON estimates(company_id);

-- ============================================================================
-- PROPOSALS
-- ============================================================================

CREATE TABLE IF NOT EXISTS proposals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estimate_id UUID REFERENCES estimates(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  proposal_document_url TEXT, -- Google Docs/Drive URL
  sent_at TIMESTAMPTZ,
  viewed_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  rejected_at TIMESTAMPTZ,
  status TEXT DEFAULT 'draft', -- draft|sent|viewed|accepted|rejected
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_proposals_estimate ON proposals(estimate_id);
CREATE INDEX idx_proposals_company ON proposals(company_id);
CREATE INDEX idx_proposals_status ON proposals(status);

-- ============================================================================
-- PAYMENTS & CONTRACTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  proposal_id UUID REFERENCES proposals(id) ON DELETE SET NULL,
  stripe_payment_intent_id TEXT,
  stripe_checkout_session_id TEXT,
  amount_chf NUMERIC(10,2),
  payment_type TEXT, -- deposit|balance|subscription
  status TEXT DEFAULT 'pending', -- pending|succeeded|failed|refunded
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  proposal_id UUID REFERENCES proposals(id) ON DELETE SET NULL,
  contract_document_url TEXT, -- Google Docs/DocuSign
  signed_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending', -- pending|signed|expired
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_payments_company ON payments(company_id);
CREATE INDEX idx_payments_stripe_intent ON payments(stripe_payment_intent_id);
CREATE INDEX idx_contracts_company ON contracts(company_id);

-- ============================================================================
-- PROJECTS & DELIVERY
-- ============================================================================

CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  notion_page_id TEXT,
  google_drive_folder_id TEXT,
  status TEXT DEFAULT 'onboarding', -- onboarding|dev|uat|live|maintenance
  onboarded_at TIMESTAMPTZ,
  dev_started_at TIMESTAMPTZ,
  uat_started_at TIMESTAMPTZ,
  go_live_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS project_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending', -- pending|in_progress|completed|blocked
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_projects_company ON projects(company_id);
CREATE INDEX idx_milestones_project ON project_milestones(project_id);

-- ============================================================================
-- MAINTENANCE & REPORTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS maintenance_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  report_period TEXT, -- YYYY-MM
  executions_count INTEGER,
  hours_saved NUMERIC(10,2),
  errors_count INTEGER,
  uptime_percent NUMERIC(5,2),
  improvements_suggested JSONB,
  report_document_url TEXT,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS nps_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  score INTEGER CHECK (score BETWEEN 0 AND 10),
  feedback TEXT,
  responded_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_maintenance_reports_project ON maintenance_reports(project_id);
CREATE INDEX idx_nps_company ON nps_responses(company_id);

-- ============================================================================
-- TECHNICAL TABLES (Observability & Idempotence)
-- ============================================================================

CREATE TABLE IF NOT EXISTS execution_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow TEXT NOT NULL,
  run_id TEXT,
  step TEXT,
  level TEXT NOT NULL, -- info|warn|error
  message TEXT NOT NULL,
  payload JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS idempotency_keys (
  key TEXT PRIMARY KEY,
  workflow TEXT NOT NULL,
  processed_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_execution_logs_workflow ON execution_logs(workflow, created_at DESC);
CREATE INDEX idx_execution_logs_level ON execution_logs(level);
CREATE INDEX idx_idempotency_keys_workflow ON idempotency_keys(workflow);

-- ============================================================================
-- VIEWS (helpful queries)
-- ============================================================================

CREATE OR REPLACE VIEW pipeline_overview AS
SELECT
  status,
  COUNT(*) as count,
  COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percent
FROM companies
GROUP BY status;

CREATE OR REPLACE VIEW recent_conversions AS
SELECT
  c.name as company,
  c.status,
  p.sent_at,
  p.accepted_at,
  EXTRACT(EPOCH FROM (p.accepted_at - p.sent_at))/86400 as days_to_accept,
  pay.amount_chf
FROM companies c
JOIN proposals p ON p.company_id = c.id
LEFT JOIN payments pay ON pay.proposal_id = p.id
WHERE p.accepted_at IS NOT NULL
ORDER BY p.accepted_at DESC
LIMIT 20;

-- ============================================================================
-- FUNCTIONS (auto-update timestamps)
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER companies_updated_at BEFORE UPDATE ON companies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER contacts_updated_at BEFORE UPDATE ON contacts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER audits_updated_at BEFORE UPDATE ON audits
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER specs_updated_at BEFORE UPDATE ON specs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER estimates_updated_at BEFORE UPDATE ON estimates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER proposals_updated_at BEFORE UPDATE ON proposals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER payments_updated_at BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER contracts_updated_at BEFORE UPDATE ON contracts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER projects_updated_at BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_execution_logs_created_at ON execution_logs(created_at DESC);
CREATE INDEX idx_idempotency_keys_created_at ON idempotency_keys(created_at);

-- Auto-cleanup old logs (optional, can be run via cron/pg_cron)
-- DELETE FROM execution_logs WHERE created_at < now() - interval '90 days';
-- DELETE FROM idempotency_keys WHERE created_at < now() - interval '180 days';
