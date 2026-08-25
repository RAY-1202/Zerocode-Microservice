<template>
  <a-layout class="basic-layout">
    <GlobalHeader v-if="!immersiveRoute" />
    <a-layout-content class="main-content">
      <router-view />
    </a-layout-content>
    <GlobalFooter v-if="!immersiveRoute" />
  </a-layout>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import GlobalHeader from '@/components/GlobalHeader.vue'
import GlobalFooter from '@/components/GlobalFooter.vue'

const route = useRoute()
const immersiveRoute = computed(() => route.path.startsWith('/app/chat/'))
</script>

<style scoped>
.basic-layout {
  min-height: 100vh;
  background: var(--ink);
}

.main-content {
  width: 100%;
  padding: 0;
  background: var(--ink);
  margin: 0;
}
</style>
