<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { GithubOutlined, LogoutOutlined, MenuOutlined } from '@ant-design/icons-vue'
import { useLoginUserStore } from '@/stores/loginUser'
import { logout } from '@/api/userController'

const route = useRoute()
const router = useRouter()
const loginUserStore = useLoginUserStore()
const mobileOpen = ref(false)
const selectedKeys = ref<string[]>([route.path])

watch(
  () => route.path,
  (path) => {
    selectedKeys.value = [path]
    mobileOpen.value = false
  },
)

const links = computed(() => {
  const items = [
    { key: '/', label: '创作首页' },
    { key: 'github', label: 'GitHub', external: true },
  ]

  if (loginUserStore.loginUser.userRole === 'admin') {
    items.splice(1, 0,
      { key: '/admin/userManage', label: '用户', external: false },
      { key: '/admin/chatManage', label: '对话', external: false },
      { key: '/admin/appManage', label: '应用', external: false },
    )
  }

  return items
})

const goTo = (item: { key: string; external?: boolean }) => {
  if (item.external) {
    window.open('https://github.com/RAY-1202/Zerocode-Microservice', '_blank', 'noopener,noreferrer')
    return
  }
  router.push(item.key)
}

const doLogout = async () => {
  const res = await logout()
  if (res.data.code === 0) {
    loginUserStore.setLoginUser({ userName: '未登录' })
    message.success('已退出登录')
    await router.push('/user/login')
    return
  }
  message.error(`退出失败：${res.data.message}`)
}
</script>

<template>
  <header class="site-header">
    <div class="header-shell">
      <RouterLink class="brand" to="/" aria-label="Zerocode 首页">
        <span class="brand-mark" aria-hidden="true"><span></span><span></span></span>
        <span>Zerocode</span>
      </RouterLink>

      <nav class="desktop-nav" aria-label="主导航">
        <button
          v-for="item in links"
          :key="item.key"
          class="nav-link"
          :class="{ active: selectedKeys.includes(item.key) }"
          type="button"
          @click="goTo(item)"
        >
          {{ item.label }}
          <GithubOutlined v-if="item.external" />
        </button>
      </nav>

      <div class="account-actions">
        <a-dropdown v-if="loginUserStore.loginUser.id" placement="bottomRight">
          <button class="profile-button" type="button">
            <a-avatar :src="loginUserStore.loginUser.userAvatar" :size="30">
              {{ loginUserStore.loginUser.userName?.slice(0, 1) || 'U' }}
            </a-avatar>
            <span>{{ loginUserStore.loginUser.userName || '创作者' }}</span>
          </button>
          <template #overlay>
            <a-menu>
              <a-menu-item @click="doLogout"><LogoutOutlined /> 退出登录</a-menu-item>
            </a-menu>
          </template>
        </a-dropdown>
        <RouterLink v-else class="login-button" to="/user/login">登录创作</RouterLink>
        <button class="mobile-toggle" type="button" aria-label="打开导航" @click="mobileOpen = !mobileOpen">
          <MenuOutlined />
        </button>
      </div>
    </div>

    <nav v-if="mobileOpen" class="mobile-nav" aria-label="移动端导航">
      <button v-for="item in links" :key="item.key" type="button" @click="goTo(item)">
        {{ item.label }}
      </button>
    </nav>
  </header>
</template>

<style scoped>
.site-header {
  position: fixed;
  z-index: 1000;
  top: 18px;
  right: 0;
  left: 0;
  pointer-events: none;
}

.header-shell {
  width: min(1180px, calc(100% - 32px));
  height: 64px;
  margin: 0 auto;
  padding: 0 12px 0 18px;
  border: 1px solid rgba(242, 240, 232, 0.17);
  border-radius: 18px;
  background: rgba(12, 15, 12, 0.78);
  box-shadow: 0 18px 80px rgba(0, 0, 0, 0.26);
  backdrop-filter: blur(22px);
  display: flex;
  align-items: center;
  justify-content: space-between;
  pointer-events: auto;
}

.brand,
.profile-button,
.account-actions,
.desktop-nav {
  display: flex;
  align-items: center;
}

.brand {
  gap: 11px;
  color: var(--paper);
  font-size: 19px;
  font-weight: 800;
  letter-spacing: -0.03em;
  text-decoration: none;
}

.brand-mark {
  width: 25px;
  height: 25px;
  position: relative;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 3px;
  transform: rotate(-8deg);
}

.brand-mark span {
  border-radius: 4px;
  background: var(--acid);
}

.brand-mark span:last-child {
  margin-top: 7px;
  background: var(--paper);
}

.desktop-nav {
  gap: 4px;
}

.nav-link {
  padding: 10px 13px;
  border: 0;
  border-radius: 11px;
  background: transparent;
  color: #a8aea7;
  cursor: pointer;
  font-size: 14px;
  transition: 180ms ease;
}

.nav-link:hover,
.nav-link.active {
  background: rgba(242, 240, 232, 0.09);
  color: var(--paper);
}

.account-actions {
  gap: 8px;
}

.profile-button,
.mobile-toggle {
  border: 0;
  background: transparent;
  color: var(--paper);
  cursor: pointer;
}

.profile-button {
  gap: 9px;
}

.login-button {
  padding: 11px 17px;
  border-radius: 11px;
  background: var(--acid);
  color: var(--ink);
  font-size: 14px;
  font-weight: 800;
  text-decoration: none;
}

.mobile-toggle {
  display: none;
  padding: 9px;
  font-size: 18px;
}

.mobile-nav {
  width: min(480px, calc(100% - 32px));
  margin: 8px auto 0;
  padding: 10px;
  border: 1px solid var(--line);
  border-radius: 16px;
  background: rgba(12, 15, 12, 0.96);
  pointer-events: auto;
}

.mobile-nav button {
  width: 100%;
  padding: 13px;
  border: 0;
  border-bottom: 1px solid var(--line);
  background: transparent;
  color: var(--paper);
  text-align: left;
}

.mobile-nav button:last-child {
  border-bottom: 0;
}

@media (max-width: 760px) {
  .site-header {
    top: 10px;
  }

  .header-shell {
    width: calc(100% - 20px);
    height: 58px;
  }

  .desktop-nav,
  .profile-button > span:last-child {
    display: none;
  }

  .mobile-toggle {
    display: block;
  }

  .login-button {
    padding: 9px 12px;
  }
}
</style>
