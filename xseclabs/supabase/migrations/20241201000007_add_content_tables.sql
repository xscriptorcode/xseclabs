-- ==========================================================
-- MIGRATION: Add Content Tables for Project Management
-- ==========================================================

-- Add updated_at trigger function if not exists
CREATE OR REPLACE FUNCTION public.tg_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ==========================================================
-- VULNERABILITY CATALOG + FINDINGS
-- ==========================================================
CREATE TABLE public.vuln_catalog (
  vuln_id bigserial PRIMARY KEY,
  code text,
  title text NOT NULL,
  description text,
  refs jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.findings (
  finding_id bigserial PRIMARY KEY,
  project_id bigint NOT NULL REFERENCES public.projects(project_id) ON DELETE CASCADE,
  asset_id bigint REFERENCES public.assets(asset_id) ON DELETE SET NULL,
  vuln_id bigint REFERENCES public.vuln_catalog(vuln_id) ON DELETE SET NULL,
  title text NOT NULL,
  severity text NOT NULL CHECK (severity IN ('info','low','medium','high','critical')),
  status text NOT NULL DEFAULT 'open'
    CHECK (status IN ('open','in_progress','resolved','accepted','false_positive')),
  details text,
  created_by uuid REFERENCES public.users(id_uuid) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON public.findings(project_id);
CREATE INDEX ON public.findings(asset_id);

CREATE TRIGGER set_updated_at_findings
BEFORE UPDATE ON public.findings
FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();

-- ==========================================================
-- INCIDENTS + RELATIONS + TIMELINE
-- ==========================================================
CREATE TABLE public.incidents (
  incident_id bigserial PRIMARY KEY,
  project_id bigint NOT NULL REFERENCES public.projects(project_id) ON DELETE CASCADE,
  title text NOT NULL,
  severity text NOT NULL CHECK (severity IN ('low','medium','high','critical')),
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','triage','containment','eradication','recovery','closed')),
  category text,           -- phishing|malware|ransomware|data_leak|intrusion...
  detected_at timestamptz,
  closed_at timestamptz,
  created_by uuid REFERENCES public.users(id_uuid) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON public.incidents(project_id);

CREATE TABLE public.incident_assets (
  incident_id bigint NOT NULL REFERENCES public.incidents(incident_id) ON DELETE CASCADE,
  asset_id bigint NOT NULL REFERENCES public.assets(asset_id) ON DELETE CASCADE,
  PRIMARY KEY (incident_id, asset_id)
);

CREATE TABLE public.incident_events (
  event_id bigserial PRIMARY KEY,
  incident_id bigint NOT NULL REFERENCES public.incidents(incident_id) ON DELETE CASCADE,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  author uuid REFERENCES public.users(id_uuid) ON DELETE SET NULL,
  type text,               -- note|action|alert|observable|status_change
  summary text NOT NULL,
  details jsonb
);

CREATE INDEX ON public.incident_events(incident_id);

-- ==========================================================
-- EVIDENCE / ATTACHMENTS / COMMENTS / TASKS
-- ==========================================================
CREATE TABLE public.evidence (
  evidence_id bigserial PRIMARY KEY,
  project_id bigint NOT NULL REFERENCES public.projects(project_id) ON DELETE CASCADE,
  finding_id bigint REFERENCES public.findings(finding_id) ON DELETE SET NULL,
  incident_id bigint REFERENCES public.incidents(incident_id) ON DELETE SET NULL,
  title text,
  storage_url text,        -- bucket path
  hash text,
  notes text,
  added_by uuid REFERENCES public.users(id_uuid) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON public.evidence(project_id);

CREATE TABLE public.attachments (
  attachment_id bigserial PRIMARY KEY,
  project_id bigint NOT NULL REFERENCES public.projects(project_id) ON DELETE CASCADE,
  entity_type text NOT NULL,      -- finding|incident|asset|event
  entity_id bigint NOT NULL,
  storage_url text NOT NULL,
  filename text,
  content_type text,
  size_bytes bigint,
  uploaded_by uuid REFERENCES public.users(id_uuid) ON DELETE SET NULL,
  uploaded_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON public.attachments(project_id);

CREATE TABLE public.comments (
  comment_id bigserial PRIMARY KEY,
  project_id bigint NOT NULL REFERENCES public.projects(project_id) ON DELETE CASCADE,
  entity_type text NOT NULL,
  entity_id bigint NOT NULL,
  author uuid REFERENCES public.users(id_uuid) ON DELETE SET NULL,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON public.comments(project_id);

CREATE TABLE public.tasks (
  task_id bigserial PRIMARY KEY,
  project_id bigint NOT NULL REFERENCES public.projects(project_id) ON DELETE CASCADE,
  entity_type text,        -- optional: finding|incident
  entity_id bigint,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','doing','blocked','done')),
  priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('low','medium','high','urgent')),
  assignee uuid REFERENCES public.users(id_uuid) ON DELETE SET NULL,
  due_date date,
  created_by uuid REFERENCES public.users(id_uuid) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON public.tasks(project_id);

-- ==========================================================
-- IOCs (Indicators of Compromise)
-- ==========================================================
CREATE TABLE public.iocs (
  ioc_id bigserial PRIMARY KEY,
  project_id bigint NOT NULL REFERENCES public.projects(project_id) ON DELETE CASCADE,
  type text NOT NULL,      -- ip|domain|hash|url|email|file
  value text NOT NULL,
  description text,
  created_by uuid REFERENCES public.users(id_uuid) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON public.iocs(project_id);

CREATE TABLE public.incident_iocs (
  incident_id bigint NOT NULL REFERENCES public.incidents(incident_id) ON DELETE CASCADE,
  ioc_id bigint NOT NULL REFERENCES public.iocs(ioc_id) ON DELETE CASCADE,
  PRIMARY KEY (incident_id, ioc_id)
);

-- ==========================================================
-- ATTACK TECHNIQUES (MITRE ATT&CK)
-- ==========================================================
CREATE TABLE public.attack_techniques (
  technique_id text PRIMARY KEY,  -- T1234
  name text NOT NULL,
  description text,
  tactic text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.finding_techniques (
  finding_id bigint NOT NULL REFERENCES public.findings(finding_id) ON DELETE CASCADE,
  technique_id text NOT NULL REFERENCES public.attack_techniques(technique_id) ON DELETE CASCADE,
  PRIMARY KEY (finding_id, technique_id)
);

CREATE TABLE public.incident_techniques (
  incident_id bigint NOT NULL REFERENCES public.incidents(incident_id) ON DELETE CASCADE,
  technique_id text NOT NULL REFERENCES public.attack_techniques(technique_id) ON DELETE CASCADE,
  PRIMARY KEY (incident_id, technique_id)
);

-- ==========================================================
-- ENABLE ROW LEVEL SECURITY
-- ==========================================================
ALTER TABLE public.vuln_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.findings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iocs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_iocs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attack_techniques ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.finding_techniques ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_techniques ENABLE ROW LEVEL SECURITY;

-- ==========================================================
-- HELPER FUNCTIONS FOR RLS
-- ==========================================================
CREATE OR REPLACE FUNCTION public.member_via_incident(p_incident_id bigint)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.incidents i
    WHERE i.incident_id = p_incident_id
    AND public.is_project_member(i.project_id)
  );
$$;

CREATE OR REPLACE FUNCTION public.member_via_finding(p_finding_id bigint)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.findings f
    WHERE f.finding_id = p_finding_id
    AND public.is_project_member(f.project_id)
  );
$$;

-- ==========================================================
-- ROW LEVEL SECURITY POLICIES
-- ==========================================================

-- VULN_CATALOG: read-only for authenticated users
CREATE POLICY vuln_catalog_read_all
ON public.vuln_catalog
FOR SELECT
TO authenticated
USING (true);

-- FINDINGS (project members RW)
CREATE POLICY findings_member_select
ON public.findings
FOR SELECT
TO authenticated
USING (public.is_project_member(project_id));

CREATE POLICY findings_member_mutate
ON public.findings
FOR ALL
TO authenticated
USING (public.is_project_member(project_id))
WITH CHECK (public.is_project_member(project_id));

-- INCIDENTS (project members RW)
CREATE POLICY incidents_member_select
ON public.incidents
FOR SELECT
TO authenticated
USING (public.is_project_member(project_id));

CREATE POLICY incidents_member_mutate
ON public.incidents
FOR ALL
TO authenticated
USING (public.is_project_member(project_id))
WITH CHECK (public.is_project_member(project_id));

-- INCIDENT_ASSETS (members RW via incident)
CREATE POLICY incident_assets_member_select
ON public.incident_assets
FOR SELECT
TO authenticated
USING (public.member_via_incident(incident_id));

CREATE POLICY incident_assets_member_mutate
ON public.incident_assets
FOR ALL
TO authenticated
USING (public.member_via_incident(incident_id))
WITH CHECK (public.member_via_incident(incident_id));

-- INCIDENT_EVENTS (members RW via incident)
CREATE POLICY incident_events_member_select
ON public.incident_events
FOR SELECT
TO authenticated
USING (public.member_via_incident(incident_id));

CREATE POLICY incident_events_member_mutate
ON public.incident_events
FOR ALL
TO authenticated
USING (public.member_via_incident(incident_id))
WITH CHECK (public.member_via_incident(incident_id));

-- EVIDENCE (project members RW)
CREATE POLICY evidence_member_select
ON public.evidence
FOR SELECT
TO authenticated
USING (public.is_project_member(project_id));

CREATE POLICY evidence_member_mutate
ON public.evidence
FOR ALL
TO authenticated
USING (public.is_project_member(project_id))
WITH CHECK (public.is_project_member(project_id));

-- ATTACHMENTS (project members RW)
CREATE POLICY attachments_member_select
ON public.attachments
FOR SELECT
TO authenticated
USING (public.is_project_member(project_id));

CREATE POLICY attachments_member_mutate
ON public.attachments
FOR ALL
TO authenticated
USING (public.is_project_member(project_id))
WITH CHECK (public.is_project_member(project_id));

-- COMMENTS (project members RW)
CREATE POLICY comments_member_select
ON public.comments
FOR SELECT
TO authenticated
USING (public.is_project_member(project_id));

CREATE POLICY comments_member_mutate
ON public.comments
FOR ALL
TO authenticated
USING (public.is_project_member(project_id))
WITH CHECK (public.is_project_member(project_id));

-- TASKS (project members RW)
CREATE POLICY tasks_member_select
ON public.tasks
FOR SELECT
TO authenticated
USING (public.is_project_member(project_id));

CREATE POLICY tasks_member_mutate
ON public.tasks
FOR ALL
TO authenticated
USING (public.is_project_member(project_id))
WITH CHECK (public.is_project_member(project_id));

-- IOCS (project members RW)
CREATE POLICY iocs_member_select
ON public.iocs
FOR SELECT
TO authenticated
USING (public.is_project_member(project_id));

CREATE POLICY iocs_member_mutate
ON public.iocs
FOR ALL
TO authenticated
USING (public.is_project_member(project_id))
WITH CHECK (public.is_project_member(project_id));

-- INCIDENT_IOCS (members RW via incident)
CREATE POLICY incident_iocs_member_select
ON public.incident_iocs
FOR SELECT
TO authenticated
USING (public.member_via_incident(incident_id));

CREATE POLICY incident_iocs_member_mutate
ON public.incident_iocs
FOR ALL
TO authenticated
USING (public.member_via_incident(incident_id))
WITH CHECK (public.member_via_incident(incident_id));

-- ATTACK_TECHNIQUES: read-only for authenticated users
CREATE POLICY attack_read_all
ON public.attack_techniques
FOR SELECT
TO authenticated
USING (true);

-- FINDING_TECHNIQUES (members RW via finding)
CREATE POLICY finding_tech_member_select
ON public.finding_techniques
FOR SELECT
TO authenticated
USING (public.member_via_finding(finding_id));

CREATE POLICY finding_tech_member_mutate
ON public.finding_techniques
FOR ALL
TO authenticated
USING (public.member_via_finding(finding_id))
WITH CHECK (public.member_via_finding(finding_id));

-- INCIDENT_TECHNIQUES (members RW via incident)
CREATE POLICY incident_tech_member_select
ON public.incident_techniques
FOR SELECT
TO authenticated
USING (public.member_via_incident(incident_id));

CREATE POLICY incident_tech_member_mutate
ON public.incident_techniques
FOR ALL
TO authenticated
USING (public.member_via_incident(incident_id))
WITH CHECK (public.member_via_incident(incident_id));