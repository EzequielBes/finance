<script setup>
import { ref } from 'vue'
import { getDbInfo } from '@/db/index.js'

const dbInfo = ref(null)

function checkDb() {
  dbInfo.value = getDbInfo()
}
</script>

<template>
  <!-- PLACEHOLDER: infra verification only. Replaced by real views in sub-project 2. -->
  <div style="padding: 2rem; font-family: sans-serif">
    <h1>AnalisadorFinanceiro Local — infraestrutura OK</h1>
    <button @click="checkDb">Verificar banco local</button>
    <pre v-if="dbInfo">{{ JSON.stringify(dbInfo, null, 2) }}</pre>
  </div>
</template>
