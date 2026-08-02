# Plano de Economia (dentro de Planos)

## Contexto

Quarto e último sub-projeto do conjunto de planejamento financeiro solicitado pelo usuário:

1. Gerenciamento de Categorias (concluído — seed padrão + limite mensal)
2. Autocomplete de transações repetidas (concluído)
3. Algoritmo de análise de economia (concluído — `/reports/savings-analysis`)
4. **Plano de economia dentro de Planos** (este spec)

Fecha o pedido original: "a pessoa pode fazer uma espécie de plano a curto prazo e o sistema vai fazer uma recomendação de economia... monte um plano de economia e verifique o quanto você consegue economizar de tempo para bater a meta". Este sub-projeto consome a saída do sub-projeto 3 dentro do contexto de um Plano específico já existente.

## O que muda

### Sem endpoint novo

Este é um sub-projeto **frontend-only**. Reaproveita dois endpoints já existentes:
- `GET /reports/savings-analysis` (sub-projeto 3) — retorna categorias com `is_essential`, `current_amount`, `suggested_cut`, etc.
- `GET /plans/{plan_id}/simulate?monthly_contribution=X` (já existente antes de qualquer um dos 4 sub-projetos) — recalcula prazo/data estimada para qualquer valor de contribuição mensal hipotético, sem persistir nada.

Nenhuma tabela nova, nenhum modelo novo, nenhuma migração.

### Frontend: extensão de `PlanSimulator.vue`

O componente já existente (`frontend/src/components/plans/PlanSimulator.vue`) tem um simulador de contribuição mensal (slider + prazo recalculado via `store.simulate`). Ganha uma seção nova, logo abaixo do resultado do simulador atual:

- Ao montar o componente, busca `useReportsStore().fetchSavingsAnalysis()` e filtra a lista para `is_essential === false` (categorias cortáveis).
- **Se a lista filtrada estiver vazia, a seção inteira não renderiza** — nada para cortar, nada a mostrar.
- Se houver 1+ categorias cortáveis, mostra:
  - Um texto de convite fixo: "Você tem gastos que podem ser economizados. Monte um plano de economia e veja quanto tempo pode ganhar para bater a meta."
  - Uma lista de cards, um por categoria cortável retornada pela análise, cada um com:
    - Nome da categoria e gasto atual (`current_amount`) formatado como moeda.
    - Um slider de 0 a 100% (step razoável, ex: 5%) representando "quanto dessa categoria você economiza este mês".
    - Um valor calculado e exibido ao lado do slider: `percent/100 * current_amount`, formatado como moeda — o corte em reais que aquele percentual representa naquela categoria específica.
- Um resumo agregado, sempre visível quando a seção está ativa: soma de todos os cortes individuais (`Σ percent_i/100 * current_amount_i`) = "economia extra mensal".
- Chama `store.simulate(plan.id, plan.monthly_contribution + economia_extra_mensal)` (debounced, mesmo padrão de 400ms já usado pelo simulador de contribuição existente) sempre que qualquer slider muda.
- Mostra o resultado: novo prazo (`months_to_goal`) e nova data estimada, no mesmo formato visual já usado pelo bloco `.sim-result` existente.
- Mostra a diferença: "Você economiza N meses" comparando o novo `months_to_goal` com `plan.simulation.months_to_goal` (o prazo original do plano, já disponível na prop `plan` que o componente recebe — não precisa de uma chamada extra para obter esse valor de referência).
  - Se o novo `months_to_goal` for `null` (contribuição ainda insuficiente mesmo com os cortes) ou igual/maior que o original, não mostra a frase de economia de tempo (evita "economize -2 meses" ou comparações sem sentido).

### Interação entre os dois simuladores

O simulador de contribuição (slider único, já existente) e o novo bloco de plano de economia funcionam de forma independente — mexer no slider de contribuição não afeta os sliders de corte por categoria, e vice-versa. Ambos disparam sua própria chamada a `store.simulate` com o valor total que fizer sentido para aquele bloco (`contribution` sozinho no simulador existente; `plan.monthly_contribution + economia_extra_mensal` no bloco novo). Não há tentativa de unificar os dois em um único estado — são duas ferramentas de "e se" distintas na mesma tela.

## Fora de escopo

- Persistir/aceitar o plano de economia — os sliders são só uma ferramenta de simulação "e se", não criam uma nova `monthly_contribution` real no plano nem registram nenhum aporte. Se o usuário quiser aplicar de verdade, ele ajusta a contribuição mensal do plano manualmente (fluxo já existente) ou registra um aporte maior — este spec não adiciona um botão de "aplicar este plano de economia".
- Qualquer endpoint novo no backend — tudo é composição de dados já existentes no frontend.
- Categorias essenciais aparecendo no plano de economia, mesmo como aviso — só cortáveis entram, ponto final (mesma regra do sub-projeto 3).
- Persistir o estado dos sliders entre visitas — ao recarregar a página ou reabrir o plano, os sliders voltam a 0%.
- Qualquer análise ou dado além do que `/reports/savings-analysis` já fornece — se uma categoria não aparece lá (porque está abaixo de 80% do limite/média), ela não aparece aqui também.

## Testabilidade

Sem testes automatizados de frontend neste projeto (confirmado nos sub-projetos anteriores) — verificação manual via browser: com uma conta tendo categorias cortáveis acima de 80% (montada nos testes ao vivo do sub-projeto 3), abrir um Plano ativo e confirmar que a seção de plano de economia aparece com as categorias corretas; mover um slider e confirmar que o valor de corte em reais e o prazo recalculado atualizam corretamente (debounced); confirmar que "economize N meses" só aparece quando o novo prazo é estritamente menor que o original; com uma conta sem nenhuma categoria cortável no relatório, confirmar que a seção inteira não aparece.

Sem testes de backend necessários — nenhum endpoint novo é criado.
