<script setup lang="ts">
import { CodeOutlined, ExportOutlined, MessageOutlined } from '@ant-design/icons-vue'

interface Props {
  app: API.AppVO
  featured?: boolean
}

interface Emits {
  (e: 'view-chat', appId: string | number | undefined): void
  (e: 'view-work', app: API.AppVO): void
}

const props = withDefaults(defineProps<Props>(), { featured: false })
const emit = defineEmits<Emits>()
</script>

<template>
  <article class="app-card" :class="{ featured }">
    <div class="app-preview">
      <img v-if="app.cover" :src="app.cover" :alt="app.appName || '应用预览'" />
      <div v-else class="app-placeholder"><CodeOutlined /></div>
      <div class="app-overlay">
        <button type="button" @click="emit('view-chat', app.id)"><MessageOutlined /> 查看对话</button>
        <button v-if="app.deployKey" type="button" @click="emit('view-work', app)"><ExportOutlined /> 打开作品</button>
      </div>
    </div>
    <div class="app-info">
      <a-avatar :src="app.user?.userAvatar" :size="34">
        {{ app.user?.userName?.charAt(0) || 'U' }}
      </a-avatar>
      <div>
        <h3>{{ app.appName || '未命名应用' }}</h3>
        <p>{{ app.user?.userName || (featured ? '精选作品' : '我的项目') }}</p>
      </div>
      <span class="card-arrow"><ExportOutlined /></span>
    </div>
  </article>
</template>

<style scoped>
.app-card {
  border: 1px solid var(--line);
  border-radius: 20px;
  background: #111411;
  overflow: hidden;
  transition: transform 260ms ease, border-color 260ms ease;
}

.app-card:hover {
  border-color: rgba(199, 255, 66, 0.48);
  transform: translateY(-5px);
}

.app-preview {
  position: relative;
  height: 220px;
  background:
    linear-gradient(135deg, rgba(199, 255, 66, 0.12), transparent 55%),
    #181c18;
  overflow: hidden;
}

.app-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 700ms ease;
}

.app-card:hover img {
  transform: scale(1.05);
}

.app-placeholder {
  height: 100%;
  display: grid;
  place-items: center;
  color: var(--acid);
  font-size: 44px;
}

.app-overlay {
  position: absolute;
  inset: 0;
  padding: 16px;
  background: rgba(6, 8, 7, 0.72);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 8px;
  opacity: 0;
  transition: opacity 260ms ease;
}

.app-card:hover .app-overlay,
.app-card:focus-within .app-overlay {
  opacity: 1;
}

.app-overlay button {
  padding: 10px 12px;
  border: 1px solid rgba(242, 240, 232, 0.24);
  border-radius: 10px;
  background: var(--paper);
  color: var(--ink);
  cursor: pointer;
  font-weight: 700;
}

.app-overlay button:last-child {
  background: var(--acid);
}

.app-info {
  padding: 16px;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 12px;
}

.app-info h3,
.app-info p {
  margin: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.app-info h3 {
  color: var(--paper);
  font-size: 16px;
}

.app-info p {
  margin-top: 3px;
  color: var(--muted);
  font-size: 13px;
}

.card-arrow {
  color: #737a73;
}

@media (hover: none) {
  .app-overlay {
    position: static;
    padding-top: 0;
    background: transparent;
    opacity: 1;
  }
}
</style>
