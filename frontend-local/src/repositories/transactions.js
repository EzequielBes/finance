import { db } from '../db/index.js'

function addMonths(dateStr, months) {
  const [y, m, d] = dateStr.split('-').map(Number)
  const date = new Date(y, m - 1 + months, d)
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}

function lastDayOfMonth(year, month) {
  return new Date(year, month, 0).getDate()
}

export async function list({ month, year, category_id, type, page = 1, per_page = 50 } = {}) {
  let all = await db.transactions.toArray()

  if (year && month) {
    const start = `${year}-${String(month).padStart(2, '0')}-01`
    const end = `${year}-${String(month).padStart(2, '0')}-${String(lastDayOfMonth(year, month)).padStart(2, '0')}`
    all = all.filter((tx) => tx.date >= start && tx.date <= end)
  } else if (year) {
    all = all.filter((tx) => tx.date >= `${year}-01-01` && tx.date <= `${year}-12-31`)
  }

  if (category_id != null) {
    all = all.filter((tx) => tx.category_id === category_id)
  }
  if (type) {
    all = all.filter((tx) => tx.type === type)
  }

  all.sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0))

  const total = all.length
  const startIdx = (page - 1) * per_page
  const items = all.slice(startIdx, startIdx + per_page)
  return { items, total }
}

export async function create(payload) {
  if (payload.installments_total && payload.installments_total > 1) {
    const groupId = crypto.randomUUID()
    const rows = []
    for (let i = 1; i <= payload.installments_total; i++) {
      rows.push({
        category_id: payload.category_id,
        description: `${payload.description} (${i}/${payload.installments_total})`,
        amount: payload.amount,
        date: i === 1 ? payload.date : addMonths(payload.date, i - 1),
        type: payload.type,
        is_recurring: false,
        recurrence_period: null,
        installments_total: payload.installments_total,
        installments_current: i,
        installment_group_id: groupId,
        created_at: new Date().toISOString(),
      })
    }
    const ids = await db.transactions.bulkAdd(rows, { allKeys: true })
    return { ...rows[0], id: ids[0] }
  }

  const row = {
    category_id: payload.category_id,
    description: payload.description,
    amount: payload.amount,
    date: payload.date,
    type: payload.type,
    is_recurring: payload.is_recurring || false,
    recurrence_period: payload.recurrence_period || null,
    installments_total: null,
    installments_current: null,
    installment_group_id: null,
    created_at: new Date().toISOString(),
  }
  const id = await db.transactions.add(row)
  return { ...row, id }
}

export async function update(id, payload) {
  const allowed = {}
  if ('description' in payload) allowed.description = payload.description
  if ('amount' in payload) allowed.amount = payload.amount
  if ('date' in payload) allowed.date = payload.date
  if ('category_id' in payload) allowed.category_id = payload.category_id
  await db.transactions.update(id, allowed)
}

export async function remove(id) {
  await db.transactions.delete(id)
}

export async function getSuggestions(query) {
  const q = query.toLowerCase()
  const all = await db.transactions
    .filter((tx) => tx.description.toLowerCase().includes(q))
    .toArray()
  all.sort((a, b) => {
    if (a.date !== b.date) return a.date < b.date ? 1 : -1
    return (b.id || 0) - (a.id || 0)
  })
  const seen = new Map()
  for (const tx of all) {
    const key = tx.description.toLowerCase()
    if (!seen.has(key)) {
      seen.set(key, { description: tx.description, amount: tx.amount, category_id: tx.category_id, type: tx.type })
    }
    if (seen.size >= 5) break
  }
  return Array.from(seen.values())
}
