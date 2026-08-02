import { db } from '../db/index.js'

function lastDayOfMonth(year, month) {
  return new Date(year, month, 0).getDate()
}

function subtractMonths(date, months) {
  const d = new Date(date.getFullYear(), date.getMonth() - months, date.getDate())
  return d
}

function toIso(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export async function list({ month, year } = {}) {
  let all = await db.incomeEntries.toArray()
  if (year) {
    if (month) {
      const start = `${year}-${String(month).padStart(2, '0')}-01`
      const end = `${year}-${String(month).padStart(2, '0')}-${String(lastDayOfMonth(year, month)).padStart(2, '0')}`
      all = all.filter((e) => e.date >= start && e.date <= end)
    } else {
      all = all.filter((e) => e.date >= `${year}-01-01` && e.date <= `${year}-12-31`)
    }
  }
  all.sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0))
  return all
}

export async function create(payload) {
  const row = {
    amount: payload.amount,
    date: payload.date,
    source: payload.source,
    is_recurring: payload.is_recurring || false,
    recurrence_period: payload.recurrence_period || null,
    notes: payload.notes || null,
    created_at: new Date().toISOString(),
  }
  const id = await db.incomeEntries.add(row)
  return { ...row, id }
}

export async function update(id, payload) {
  await db.incomeEntries.update(id, payload)
}

export async function remove(id) {
  await db.incomeEntries.delete(id)
}

export async function getSummary() {
  const today = new Date()
  const threeMonthsAgo = subtractMonths(today, 3)
  const all = await db.incomeEntries.toArray()

  const inLast3Months = all.filter((e) => e.date >= toIso(threeMonthsAgo) && e.date <= toIso(today))
  const average = inLast3Months.length
    ? inLast3Months.reduce((sum, e) => sum + e.amount, 0) / inLast3Months.length
    : 0

  const monthStart = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-01`
  const monthEnd = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(lastDayOfMonth(today.getFullYear(), today.getMonth() + 1)).padStart(2, '0')}`
  const thisMonth = all.filter((e) => e.date >= monthStart && e.date <= monthEnd)
  const total = thisMonth.reduce((sum, e) => sum + e.amount, 0)

  return {
    average_last_3_months: Math.round(average * 100) / 100,
    total_this_month: Math.round(total * 100) / 100,
  }
}
