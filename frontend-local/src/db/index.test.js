import { describe, it, expect, beforeEach } from 'vitest'
import { db, getDbInfo } from './index.js'

describe('db setup', () => {
  beforeEach(async () => {
    await db.transactions.clear()
  })

  it('exposes all five tables', () => {
    const info = getDbInfo()
    expect(info.tables).toEqual(['categories', 'transactions', 'incomeEntries', 'plans', 'planContributions'])
  })

  it('can write and read a row via fake-indexeddb', async () => {
    const id = await db.transactions.add({ description: 'test', amount: 10, date: '2026-01-01', type: 'expense' })
    const row = await db.transactions.get(id)
    expect(row.description).toBe('test')
  })
})
