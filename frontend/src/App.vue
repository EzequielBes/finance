<script setup>
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
const auth = useAuthStore()
onMounted(() => auth.fetchMe())
</script>

<template>
  <RouterView />
</template>
