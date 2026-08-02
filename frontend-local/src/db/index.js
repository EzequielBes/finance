import Dexie from 'dexie'

export const db = new Dexie('AnalisadorFinanceiroLocal')

db.version(1).stores({
  categories: '++id, name, type',
  transactions: '++id, category_id, date, type',
  incomeEntries: '++id, date',
  plans: '++id, parent_plan_id, status',
  planContributions: '++id, plan_id, date',
})

db.version(2).stores({
  transactions: '++id, category_id, date, type, installment_group_id, description',
})

export function getDbInfo() {
  return {
    name: db.name,
    tables: db.tables.map((t) => t.name),
  }
}
