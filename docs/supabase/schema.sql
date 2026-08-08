-- ============================================================
-- AnalisadorFinanceiro — Supabase Multi-Agent Communication
-- Execute este arquivo no SQL Editor do Supabase
-- ============================================================

-- Habilita UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. Registro de agentes
-- ============================================================
CREATE TABLE IF NOT EXISTS agents (
  id          TEXT PRIMARY KEY,              -- 'agy', 'claude', 'codex'
  status      TEXT NOT NULL DEFAULT 'idle',  -- 'idle','working','blocked','done'
  current_task_id UUID,
  last_seen   TIMESTAMPTZ DEFAULT NOW(),
  metadata    JSONB DEFAULT '{}'
);

INSERT INTO agents (id) VALUES ('agy'), ('claude'), ('codex')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 2. Fila de tarefas
-- ============================================================
CREATE TABLE IF NOT EXISTS tasks (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title        TEXT NOT NULL,
  description  TEXT,
  assigned_to  TEXT REFERENCES agents(id),
  created_by   TEXT REFERENCES agents(id),
  status       TEXT NOT NULL DEFAULT 'pending',
  -- 'pending','in_progress','blocked','done','cancelled'
  priority     INT DEFAULT 5,  -- 1=alta, 10=baixa
  branch       TEXT,           -- worktree/branch do git a usar
  file_scope   TEXT[],         -- arquivos que pode tocar
  context      JSONB DEFAULT '{}',
  result       TEXT,
  error        TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  started_at   TIMESTAMPTZ,
  finished_at  TIMESTAMPTZ
);

-- ============================================================
-- 3. Canal de mensagens entre agentes
-- ============================================================
CREATE TABLE IF NOT EXISTS messages (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_agent  TEXT REFERENCES agents(id),
  to_agent    TEXT REFERENCES agents(id),  -- NULL = broadcast
  task_id     UUID REFERENCES tasks(id),
  content     TEXT NOT NULL,
  type        TEXT DEFAULT 'info',  -- 'info','request','result','error'
  read        BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. Artefatos produzidos pelos agentes
-- ============================================================
CREATE TABLE IF NOT EXISTS artifacts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id     UUID REFERENCES tasks(id),
  created_by  TEXT REFERENCES agents(id),
  type        TEXT,        -- 'code','file','analysis','plan'
  file_path   TEXT,        -- caminho relativo no projeto
  content     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. Log de progresso do projeto
-- ============================================================
CREATE TABLE IF NOT EXISTS progress_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id    TEXT REFERENCES agents(id),
  task_id     UUID REFERENCES tasks(id),
  message     TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. Realtime — habilita para todas as tabelas
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE agents;
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE artifacts;
ALTER PUBLICATION supabase_realtime ADD TABLE progress_log;

-- ============================================================
-- 7. Row Level Security — leitura pública para os agentes
-- (ajuste conforme necessidade de segurança)
-- ============================================================
ALTER TABLE agents        ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks         ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages      ENABLE ROW LEVEL SECURITY;
ALTER TABLE artifacts     ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_log  ENABLE ROW LEVEL SECURITY;

-- Política simples: service_role tem acesso total (usado pelo MCP)
CREATE POLICY "service_role_all" ON agents        FOR ALL USING (true);
CREATE POLICY "service_role_all" ON tasks         FOR ALL USING (true);
CREATE POLICY "service_role_all" ON messages      FOR ALL USING (true);
CREATE POLICY "service_role_all" ON artifacts     FOR ALL USING (true);
CREATE POLICY "service_role_all" ON progress_log  FOR ALL USING (true);
