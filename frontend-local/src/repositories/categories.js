import { db } from '../db/index.js'

const DEFAULT_CATEGORIES = [
  { name: 'Moradia', type: 'expense', color: '#c17a54', icon: 'bank' },
  { name: 'Alimentação', type: 'expense', color: '#7a9b7e', icon: 'tag' },
  { name: 'Transporte', type: 'expense', color: '#8a9bb0', icon: 'transactions' },
  { name: 'Saúde', type: 'expense', color: '#b8563a', icon: 'tag' },
  { name: 'Lazer', type: 'expense', color: '#c17a54', icon: 'tag' },
  { name: 'Compras', type: 'expense', color: '#7a9b7e', icon: 'wallet' },
  { name: 'Educação', type: 'expense', color: '#8a9bb0', icon: 'tag' },
  { name: 'Contas fixas', type: 'expense', color: '#b8563a', icon: 'bank' },
  { name: 'Salário', type: 'income', color: '#7a9b7e', icon: 'trending-up' },
  { name: 'Freelance', type: 'income', color: '#c17a54', icon: 'trending-up' },
  { name: 'Outros rendimentos', type: 'income', color: '#8a9bb0', icon: 'trending-up' },
]

function monthRange(today = new Date()) {
  const start = new Date(today.getFullYear(), today.getMonth(), 1)
  const end = new Date(today.getFullYear(), today.getMonth() + 1, 0)
  const toIso = (d) => d.toISOString().slice(0, 10)
  return { start: toIso(start), end: toIso(end) }
}

export async function list() {
  const categories = await db.categories.toArray()
  const { start, end } = monthRange()
  const usageByCategory = {}
  const transactions = await db.transactions
    .where('date')
    .between(start, end, true, true)
    .toArray()
  for (const tx of transactions) {
    if (tx.type !== 'expense' || tx.category_id == null) continue
    usageByCategory[tx.category_id] = (usageByCategory[tx.category_id] || 0) + tx.amount
  }
  return categories.map((cat) => ({
    ...cat,
    current_month_usage: Math.round((usageByCategory[cat.id] || 0) * 100) / 100,
  }))
}

export async function create(payload) {
  const id = await db.categories.add(payload)
  return { ...payload, id, current_month_usage: 0 }
}

export async function update(id, payload) {
  await db.categories.update(id, payload)
  return { ...payload, id }
}

export async function seedDefaults() {
  const existing = await db.categories.toArray()
  const existingNames = new Set(existing.map((c) => c.name.toLowerCase()))
  const created = []
  for (const def of DEFAULT_CATEGORIES) {
    if (existingNames.has(def.name.toLowerCase())) continue
    const id = await db.categories.add({ ...def, monthly_limit: null })
    created.push({ ...def, id, monthly_limit: null })
  }
  return created
}
