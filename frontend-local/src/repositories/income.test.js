import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest'
import { db } from '../db/index.js'
import { list, create, update, remove, getSummary } from './income.js'

describe('income repository', () => {
  beforeEach(async () => {
    await db.incomeEntries.clear()
  })

  it('create() inserts an entry', async () => {
    const entry = await create({ amount: 5000, date: '2026-03-01', source: 'Salário', is_recurring: true, recurrence_period: 'monthly', notes: null })
    expect(entry.id).toBeDefined()
    const items = await list({})
    expect(items).toHaveLength(1)
    expect(items[0].source).toBe('Salário')
  })

  it('list() filters by month and year', async () => {
    await create({ amount: 100, date: '2026-03-01', source: 'A', is_recurring: false, recurrence_period: null, notes: null })
    await create({ amount: 200, date: '2026-04-01', source: 'B', is_recurring: false, recurrence_period: null, notes: null })
    const items = await list({ month: 3, year: 2026 })
    expect(items).toHaveLength(1)
    expect(items[0].source).toBe('A')
  })

  it('update() changes fields', async () => {
    const entry = await create({ amount: 100, date: '2026-03-01', source: 'A', is_recurring: false, recurrence_period: null, notes: null })
    await update(entry.id, { source: 'A editado' })
    const items = await list({})
    expect(items[0].source).toBe('A editado')
  })

  it('remove() deletes an entry', async () => {
    const entry = await create({ amount: 100, date: '2026-03-01', source: 'A', is_recurring: false, recurrence_period: null, notes: null })
    await remove(entry.id)
    const items = await list({})
    expect(items).toHaveLength(0)
  })

  it('getSummary() computes average of last 3 months and total of current month', async () => {
    const realDate = Date
    const fixedToday = new realDate(2026, 2, 20) // 2026-03-20
    global.Date = class extends realDate {
      constructor(...args) {
        if (args.length === 0) return fixedToday
        return new realDate(...args)
      }
      static now() { return fixedToday.getTime() }
    }

    await create({ amount: 5000, date: '2026-01-05', source: 'Salário', is_recurring: true, recurrence_period: 'monthly', notes: null })
    await create({ amount: 5500, date: '2026-02-05', source: 'Salário', is_recurring: true, recurrence_period: 'monthly', notes: null })
    await create({ amount: 6000, date: '2026-03-05', source: 'Salário', is_recurring: true, recurrence_period: 'monthly', notes: null })

    const summary = await getSummary()
    expect(summary.average_last_3_months).toBeCloseTo(5500, 1)
    expect(summary.total_this_month).toBe(6000)

    global.Date = realDate
  })
})
