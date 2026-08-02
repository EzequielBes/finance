import { describe, it, expect, beforeEach, vi } from 'vitest'
import { db } from '../db/index.js'
import { list, create, update, seedDefaults } from './categories.js'

describe('categories repository', () => {
  beforeEach(async () => {
    await db.categories.clear()
    await db.transactions.clear()
  })

  it('create() inserts a category', async () => {
    const cat = await create({ name: 'Lazer', type: 'expense', color: '#c17a54', icon: 'tag', monthly_limit: null })
    expect(cat.id).toBeDefined()
    const all = await list()
    expect(all).toHaveLength(1)
    expect(all[0].name).toBe('Lazer')
  })

  it('update() changes fields', async () => {
    const cat = await create({ name: 'Lazer', type: 'expense', color: '#c17a54', icon: 'tag', monthly_limit: null })
    await update(cat.id, { name: 'Lazer e Hobbies', type: 'expense', color: '#000000', icon: 'tag', monthly_limit: 300 })
    const all = await list()
    expect(all[0].name).toBe('Lazer e Hobbies')
    expect(all[0].monthly_limit).toBe(300)
  })

  it('seedDefaults() inserts 11 default categories', async () => {
    await seedDefaults()
    const all = await list()
    expect(all).toHaveLength(11)
  })

  it('seedDefaults() is idempotent — running twice does not duplicate', async () => {
    await seedDefaults()
    await seedDefaults()
    const all = await list()
    expect(all).toHaveLength(11)
  })

  it('seedDefaults() skips existing categories by name, case-insensitive', async () => {
    await create({ name: 'moradia', type: 'expense', color: '#000', icon: 'tag', monthly_limit: null })
    await seedDefaults()
    const all = await list()
    const moradiaCount = all.filter((c) => c.name.toLowerCase() === 'moradia').length
    expect(moradiaCount).toBe(1)
    expect(all).toHaveLength(11)
  })

  it('list() computes current_month_usage from expense transactions this month', async () => {
    const cat = await create({ name: 'Lazer', type: 'expense', color: '#c17a54', icon: 'tag', monthly_limit: 200 })
    const today = new Date()
    const thisMonth = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-15`
    await db.transactions.add({ category_id: cat.id, description: 'Cinema', amount: 150, date: thisMonth, type: 'expense' })
    await db.transactions.add({ category_id: cat.id, description: 'Reembolso', amount: 50, date: thisMonth, type: 'income' })
    const all = await list()
    expect(all[0].current_month_usage).toBe(150)
  })
})
