# Redesign visual do frontend + correção do bug de login

## Contexto

O frontend (Vue 3 + Vite, plano 3 já mergeado) hoje usa um dark mode roxo/indigo genérico com glassmorphism padrão — a mesma estética que qualquer gerador de UI produz por default. Além disso, clicar em "Entrar" na tela de login recarrega a página inteira sem mostrar mensagem de erro, mesmo com `@submit.prevent` no formulário.

## Bug: login recarrega a página

**Causa raiz identificada:** `frontend/src/services/api.js`, interceptor de resposta do axios. Qualquer resposta HTTP 401 disparava `window.location.href = '/login'` — incluindo o próprio 401 retornado por uma tentativa de login com senha errada. Isso forçava um hard reload do browser antes que o Vue conseguisse renderizar a mensagem de erro (`error.value`), apagando o estado do componente. Confirmado via `read_network_requests`: POST `/auth/login` → 401, seguido de um novo `GET /login` (reload).

**Correção já aplicada** (fora deste spec, fix pontual): o interceptor agora ignora 401 vindo de `/auth/login` e `/auth/register`, e usa `router.push('/login')` em vez de `window.location.href` para os demais casos (evita hard reload mesmo quando a sessão expira em outra tela). Commit pendente.

Este spec cobre o que falta: garantir que a mensagem de erro apareça corretamente e ficar de olho em qualquer regressão ao tocar em `LoginView.vue` durante o redesign.

## Direção visual aprovada

Validada com o usuário via mockups (dashboard e login) no companion visual de brainstorming.

**Paleta — "Grafite quente + terracota":**
- Base: `#1a1613` (quase preto, com calor — não roxo/azul frio)
- Superfície de card: `#211d19`
- Superfície de input/fundo mais escuro: `#17130f`
- Borda sutil: `#2c2620`
- Texto primário: `#ede6dc`
- Texto secundário/muted: `#a89c8e`
- Texto terciário/labels: `#8a7d6e`
- Acento único: `#c17a54` (terracota) — usado com moderação: destaques, links ativos, o anel de progresso, botão primário
- Sucesso (receita): `#7a9b7e` (verde envelhecido, não verde neon)
- Atenção/gasto: mantém `#c17a54` ou um tom levemente mais escuro para diferenciar de "ativo neutro" — decisão de implementação, manter dentro da família quente

**Tipografia:**
- Display/números: Georgia (serifada, já disponível sem custo de carregamento de fonte externa — decisão pragmática; se o usuário preferir uma serifada mais distintiva tipo "Fraunces" ou "Lora" via Google Fonts, é uma troca de token, não de arquitetura)
- Corpo/labels/UI: Helvetica Neue / system sans-serif
- Escala tipográfica: números grandes (saldo, valores de destaque) em 32-42px serifada; títulos de seção 18-20px serifada; corpo/labels 13-14px sans; eyebrows/labels uppercase 11px sans com letter-spacing

**Layout, geral:**
- Sem glassmorphism (sem blur, sem transparências translúcidas) — superfícies sólidas com borda de 1px sutil
- Cards com `border-radius` moderado (8-10px), não excessivamente arredondado
- Espaçamento generoso — respiração é parte da sensação "sofisticada e não poluída"
- Sidebar escura ainda mais que o conteúdo principal, borda à direita sutil, item ativo com borda esquerda terracota (não fundo colorido cheio)

**Elemento assinatura:** anel de progresso circular (SVG `stroke-dasharray`/`stroke-dashoffset`, sem lib nova) representando "saúde financeira" no topo do Dashboard, com o saldo em números grandes ao lado. Substitui o layout atual de stat cards genéricos como primeira coisa vista.

**Timeline:** ganha uma trilha vertical desenhada (gradiente terracota→transparente numa pseudo-borda), pontos sólidos terracota — em vez de ícones/dots genéricos do Chart.js/CSS atual.

## Telas afetadas

Todas as views do frontend migram para os novos tokens (cor, tipografia, espaçamento), reutilizando as classes utilitárias já existentes em `assets/main.css` — que serão redefinidas com os novos valores, não recriadas do zero:
- `LoginView.vue` — cartão editorial simples, já validado em mockup
- `AppLayout.vue` / `AppSidebar.vue` — sidebar escura, item ativo com borda lateral
- `DashboardView.vue` — anel de progresso + hero de saldo + timeline com trilha, já validado em mockup
- `TransactionsView.vue`, `IncomeView.vue`, `PlansView.vue`, `ReportsView.vue` — aplicam os mesmos tokens em cards/tabelas/forms existentes, sem redesenho estrutural — são conteúdo tabular/formulário, não telas "hero"

Não há mudança de arquitetura de componentes, rotas, ou stores — é uma troca de tokens visuais (`main.css`) + reestruturação pontual do HTML do Dashboard (para o anel) e da timeline (para a trilha).

## Micro-interações (motion)

Escopo confirmado: focar nos **elementos de destaque**, não em toda a superfície de botões/cards.
- Anel de progresso anima do zero até o valor real ao montar o Dashboard (transição de `stroke-dashoffset`, ~800ms, easing suave)
- Números de destaque (saldo, valores do anel) fazem count-up ao montar
- Itens da timeline revelam em sequência (stagger leve, fade+slide sutil) em vez de aparecer tudo de uma vez
- Fora desses três pontos, o resto do app permanece com as transições básicas que já existem (`.animate-fade-in`, hover discreto em botões) — não é objetivo deste spec adicionar hover/press-state novo em todo componente

Respeitar `prefers-reduced-motion`: quando ativo, o anel e os números aparecem já no valor final, sem animação de entrada.

## Fora de escopo

- Não mexe em lógica de negócio, chamadas de API, ou estrutura de rotas
- Não adiciona bibliotecas novas de animação (CSS puro + transições Vue bastam para o escopo acima)
- Não redesenha `ReportsView.vue` além de aplicar os tokens (a view é um stub vazio — fica um stub vazio com a cor certa)
- Não adiciona dark/light mode toggle (o app já é dark-only, isso não muda)

## Testabilidade

Sem suite de testes de frontend no projeto (confirmado nas revisões do plano 3). Verificação será manual via browser (Chrome automation) comparando antes/depois nas telas principais, mais o teste funcional do fluxo de login (credenciais erradas → mensagem de erro aparece sem reload; credenciais certas → entra no dashboard).
