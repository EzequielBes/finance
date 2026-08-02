import { describe, it, expect, beforeEach } from 'vitest'
import { db } from '../db/index.js'
import { list, create, update, remove, getSuggestions } from './transactions.js'

describe('transactions repository', () => {
  beforeEach(async () => {
    await db.transactions.clear()
  })

  it('create() inserts a single non-installment transaction', async () => {
    const tx = await create({ description: 'Aluguel', amount: 1500, date: '2026-03-05', type: 'expense', category_id: 1 })
    expect(tx.id).toBeDefined()
    const { items, total } = await list({})
    expect(total).toBe(1)
    expect(items[0].description).toBe('Aluguel')
    expect(items[0].installment_group_id).toBeFalsy()
  })

  it('create() with installments_total > 1 expands into N rows sharing installment_group_id', async () => {
    await create({ description: 'Geladeira', amount: 300, date: '2026-03-10', type: 'expense', category_id: 2, installments_total: 3 })
    const { items, total } = await list({})
    expect(total).toBe(3)
    const groupIds = new Set(items.map((tx) => tx.installment_group_id))
    expect(groupIds.size).toBe(1)
    const sorted = [...items].sort((a, b) => a.installments_current - b.installments_current)
    expect(sorted[0].description).toBe('Geladeira (1/3)')
    expect(sorted[1].description).toBe('Geladeira (2/3)')
    expect(sorted[2].description).toBe('Geladeira (3/3)')
    expect(sorted[0].date).toBe('2026-03-10')
    expect(sorted[1].date).toBe('2026-04-10')
    expect(sorted[2].date).toBe('2026-05-10')
  })

  it('list() filters by month and year', async () => {
    await create({ description: 'Março', amount: 10, date: '2026-03-15', type: 'expense', category_id: 1 })
    await create({ description: 'Abril', amount: 20, date: '2026-04-15', type: 'expense', category_id: 1 })
    const { items, total } = await list({ month: 3, year: 2026 })
    expect(total).toBe(1)
    expect(items[0].description).toBe('Março')
  })

  it('list() filters by category_id and type', async () => {
    await create({ description: 'A', amount: 10, date: '2026-03-15', type: 'expense', category_id: 1 })
    await create({ description: 'B', amount: 20, date: '2026-03-15', type: 'income', category_id: 2 })
    const { items, total } = await list({ category_id: 1, type: 'expense' })
    expect(total).toBe(1)
    expect(items[0].description).toBe('A')
  })

  it('update() changes fields', async () => {
    const tx = await create({ description: 'A', amount: 10, date: '2026-03-15', type: 'expense', category_id: 1 })
    await update(tx.id, { description: 'A editado', amount: 15 })
    const { items } = await list({})
    expect(items[0].description).toBe('A editado')
    expect(items[0].amount).toBe(15)
  })

  it('remove() deletes a transaction', async () => {
    const tx = await create({ description: 'A', amount: 10, date: '2026-03-15', type: 'expense', category_id: 1 })
    await remove(tx.id)
    const { total } = await list({})
    expect(total).toBe(0)
  })

  it('getSuggestions() returns up to 5 distinct descriptions, case-insensitive match, most recent first', async () => {
    await create({ description: 'Supermercado ABC', amount: 100, date: '2026-01-01', type: 'expense', category_id: 1 })
    await create({ description: 'supermercado abc', amount: 120, date: '2026-02-01', type: 'expense', category_id: 1 })
    await create({ description: 'Supermercado XYZ', amount: 80, date: '2026-01-15', type: 'expense', category_id: 1 })
    const results = await getSuggestions('supermercado')
    expect(results.length).toBe(2)
    expect(results[0].description).toBe('supermercado abc')
    expect(results[0].amount).toBe(120)
  })
})
