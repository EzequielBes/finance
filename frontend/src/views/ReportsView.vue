<script setup>
import { onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import { useReportsStore } from '@/stores/reports'

const store = useReportsStore()

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

function usageColorClass(percent) {
  if (percent > 100) return 'usage-over'
  if (percent >= 80) return 'usage-warning'
  return 'usage-ok'
}

onMounted(() => store.fetchSavingsAnalysis())
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h1 class="page-title">Relatórios</h1>
      <p class="page-subtitle">Análise de onde você pode economizar este mês</p>
    </div>

    <div class="card">
      <div v-if="store.loading" style="text-align:center;padding:2rem;color:var(--text-muted)">Carregando...</div>
      <div v-else-if="!store.items.length" style="text-align:center;padding:2rem;color:var(--text-muted)">
        Nenhuma categoria fora do esperado este mês.
      </div>
      <div v-else class="analysis-list">
        <div v-for="item in store.items" :key="item.category_id" class="analysis-item">
          <div class="analysis-header">
            <span class="cat-color-dot" :style="{ background: item.category_color }" />
            <span class="font-semibold">{{ item.category_name }}</span>
            <span v-if="item.is_essential" class="badge badge-info">Essencial</span>
          </div>
          <div class="progress-bar" style="margin:0.5rem 0">
            <div
              :class="['progress-fill', usageColorClass(item.percent)]"
              :style="{ width: Math.min(item.percent, 100) + '%' }"
            />
          </div>
          <div class="analysis-footer text-muted text-sm">
            <span>{{ formatCurrency(item.current_amount) }} / {{ formatCurrency(item.reference_amount) }}
              ({{ item.reference_source === 'limit' ? 'limite' : 'média histórica' }})</span>
            <span :class="usageColorClass(item.percent)">{{ item.percent }}%</span>
          </div>
          <div v-if="item.suggested_cut" class="suggested-cut">
            Sugestão: economize {{ formatCurrency(item.suggested_cut) }} nesta categoria
          </div>
          <div v-else-if="item.is_essential" class="essential-notice text-muted text-sm">
            Categoria essencial — acima do esperado, mas sem sugestão de corte.
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<style scoped>
.analysis-list { display: flex; flex-direction: column; gap: 1.25rem; }
.analysis-item { padding-bottom: 1.25rem; border-bottom: 1px solid var(--border-subtle); }
.analysis-item:last-child { border-bottom: none; padding-bottom: 0; }
.analysis-header { display: flex; align-items: center; gap: 0.5rem; }
.analysis-footer { display: flex; justify-content: space-between; }
.cat-color-dot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; }
.suggested-cut {
  margin-top: 0.5rem; padding: 0.5rem 0.75rem; border-radius: var(--radius-sm);
  background: rgba(122,155,126,0.12); color: var(--accent-success); font-size: var(--font-size-sm); font-weight: 600;
}
.essential-notice { margin-top: 0.5rem; }
.usage-ok { color: var(--accent-success); }
.usage-warning { color: var(--accent-primary); }
.usage-over { color: var(--accent-danger); }
.progress-fill.usage-ok { background: var(--accent-success); }
.progress-fill.usage-warning { background: var(--accent-primary); }
.progress-fill.usage-over { background: var(--accent-danger); }
</style>
