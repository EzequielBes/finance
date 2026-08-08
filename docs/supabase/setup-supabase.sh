#!/bin/bash
# =============================================================
# setup-supabase.sh — Configura MCP do Supabase nos 3 agentes
# =============================================================
# Uso: ./docs/supabase/setup-supabase.sh
# =============================================================

set -e

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   AnalisadorFinanceiro — Supabase Multi-Agent Setup  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Você precisa de 2 coisas do painel do Supabase:"
echo "  → Project URL:        Settings > API > Project URL"
echo "  → Service Role Key:   Settings > API > service_role (secret)"
echo ""

read -rp "Cole o Project URL (ex: https://xyzabc.supabase.co): " SUPABASE_URL
read -rsp "Cole o Service Role Key: " SUPABASE_KEY
echo ""

if [[ -z "$SUPABASE_URL" || -z "$SUPABASE_KEY" ]]; then
  echo "❌ URL ou Key vazios. Abortando."
  exit 1
fi

# Salva no .env do projeto (não commitado)
ENV_FILE="$(dirname "$0")/../../.env.supabase"
cat > "$ENV_FILE" <<EOF
SUPABASE_URL=$SUPABASE_URL
SUPABASE_KEY=$SUPABASE_KEY
EOF
echo "✅ Credenciais salvas em .env.supabase (não commitado)"

# ── 1. OpenCode (Codex) ───────────────────────────────────────
OPENCODE_JSON="$(dirname "$0")/../../opencode.json"
echo ""
echo "🔧 Configurando OpenCode (Codex)..."

python3 - <<PYEOF
import json, sys

with open('$OPENCODE_JSON', 'r') as f:
    config = json.load(f)

config['mcp'] = config.get('mcp', {})
config['mcp']['supabase'] = {
    "type": "local",
    "command": "npx",
    "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--supabase-url", "$SUPABASE_URL",
        "--supabase-key", "$SUPABASE_KEY"
    ]
}

with open('$OPENCODE_JSON', 'w') as f:
    json.dump(config, f, indent=2)

print("  ✅ opencode.json atualizado")
PYEOF

# ── 2. AGY (Antigravity) ─────────────────────────────────────
AGY_MCP="$HOME/.gemini/config/mcp_config.json"
echo "🔧 Configurando AGY..."

python3 - <<PYEOF
import json, os

path = '$AGY_MCP'
if os.path.exists(path):
    with open(path, 'r') as f:
        try:
            config = json.load(f)
        except:
            config = {}
else:
    config = {}

config['mcpServers'] = config.get('mcpServers', {})
config['mcpServers']['supabase'] = {
    "command": "npx",
    "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--supabase-url", "$SUPABASE_URL",
        "--supabase-key", "$SUPABASE_KEY"
    ]
}

with open(path, 'w') as f:
    json.dump(config, f, indent=2)

print("  ✅ AGY mcp_config.json atualizado")
PYEOF

# ── 3. Claude CLI ─────────────────────────────────────────────
echo "🔧 Configurando Claude CLI..."
claude mcp add supabase \
  --command npx \
  -- -y "@supabase/mcp-server-supabase@latest" \
  --supabase-url "$SUPABASE_URL" \
  --supabase-key "$SUPABASE_KEY" 2>/dev/null \
  && echo "  ✅ Claude MCP adicionado" \
  || echo "  ⚠️  Claude CLI não encontrado — adicione manualmente depois"

# ── 4. Schema SQL ─────────────────────────────────────────────
echo ""
echo "📋 Próximo passo: aplique o schema no Supabase"
echo "   Abra: ${SUPABASE_URL}/project/default/sql/new"
echo "   Cole o conteúdo de: docs/supabase/schema.sql"
echo ""
echo "✨ Setup completo! Reinicie os terminais para ativar os MCPs."
echo ""
