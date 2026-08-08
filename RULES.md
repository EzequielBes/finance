# AnalisadorFinanceiro — Regras do Projeto Mobile

## Stack
- **Mobile:** Flutter / Dart
- **Branch principal do mobile:** `banco-local-mobile`
- **Worktrees ativos:** ver `git worktree list`

## Estrutura mobile/
```
mobile/
  lib/           ← código Dart (flutter-builder)
  test/          ← testes (flutter-builder)
  docs/          ← documentação (dart-analyst)
  android/       ← só mexer se necessário, com cuidado
  ios/           ← só mexer se necessário, com cuidado
  pubspec.yaml   ← só com aprovação do Orquestrador
```

## ⚠️ Protocolo anti-conflito de branches

Cada agente que trabalha em paralelo DEVE ter seu próprio worktree:

```bash
# Criar worktree para um novo agente
git worktree add .worktrees/<nome-feature> <branch>

# Listar worktrees ativos (nunca mexa na branch de outro)
git worktree list

# Remover worktree após merge
git worktree remove .worktrees/<nome-feature>
```

**Regra de ouro:** se `git worktree list` mostrar uma branch ocupada,
NENHUM outro agente pode fazer checkout nela. Ponto final.

## Padrões de código Flutter
- State management: use o padrão já existente no projeto
- Widgets: preferir StatelessWidget + Provider/Riverpod/BLoC
- Nomes de arquivos: snake_case
- Nomes de classes: PascalCase
- Sempre rodar `flutter analyze` antes de commitar

## Commits
- Formato: `tipo(mobile): descrição curta`
- Tipos: feat, fix, refactor, test, chore, docs
- Exemplo: `feat(mobile): adiciona tela de banco local`
