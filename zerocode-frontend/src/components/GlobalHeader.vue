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
    { key: '/', label: '作品广场' },
    { key: 'pricing', label: '定价', external: true },
    { key: 'docs', label: '文档', external: true },
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
    const targets: Record<string, string> = {
      github: 'https://github.com/RAY-1202/Zerocode-Microservice',
      docs: 'https://github.com/RAY-1202/Zerocode-Microservice#本地启动',
      pricing: 'https://github.com/RAY-1202/Zerocode-Microservice',
    }
    window.open(targets[item.key], '_blank', 'noopener,noreferrer')
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
          <GithubOutlined v-if="item.key === 'github'" />
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
        <RouterLink v-else class="plain-login" to="/user/login">登录</RouterLink>
        <RouterLink class="login-button" to="/">开始创作</RouterLink>
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
  top: 0;
  right: 0;
  left: 0;
  pointer-events: none;
  border-bottom: 1px solid #e7e9e2;
  background: rgba(249, 250, 247, 0.9);
  backdrop-filter: blur(18px);
}

.header-shell {
  width: min(1440px, calc(100% - 64px));
  height: 76px;
  margin: 0 auto;
  padding: 0;
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
  color: #11130f;
  font-size: 21px;
  font-weight: 800;
  letter-spacing: -0.03em;
  text-decoration: none;
}

.brand-mark {
  width: 30px;
  height: 26px;
  position: relative;
  display: block;
}

.brand-mark span {
  position: absolute;
  width: 28px;
  height: 9px;
  border-radius: 2px;
  background: #11130f;
  transform: skewX(-30deg);
}

.brand-mark span:last-child {
  top: 15px;
  transform: skewX(-30deg) rotate(180deg);
}

.desktop-nav {
  gap: 4px;
}

.nav-link {
  padding: 10px 13px;
  border: 0;
  border-radius: 11px;
  background: transparent;
  color: #4c514a;
  cursor: pointer;
  font-size: 14px;
  transition: 180ms ease;
}

.nav-link:hover,
.nav-link.active {
  background: #eef0ea;
  color: #11130f;
}

.account-actions {
  gap: 8px;
}

.profile-button,
.mobile-toggle {
  border: 0;
  background: transparent;
  color: #11130f;
  cursor: pointer;
}

.profile-button {
  gap: 9px;
}

.plain-login {
  padding: 10px 14px;
  color: #11130f;
  font-size: 14px;
  font-weight: 700;
  text-decoration: none;
}

.login-button {
  padding: 12px 19px;
  border-radius: 999px;
  background: #c8f43d;
  color: #11130f;
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
  border: 1px solid #e1e4db;
  border-radius: 16px;
  background: #f9faf7;
  pointer-events: auto;
}

.mobile-nav button {
  width: 100%;
  padding: 13px;
  border: 0;
  border-bottom: 1px solid #e1e4db;
  background: transparent;
  color: #11130f;
  text-align: left;
}

.mobile-nav button:last-child {
  border-bottom: 0;
}

@media (max-width: 760px) {
  .site-header {
    top: 0;
  }

  .header-shell {
    width: calc(100% - 28px);
    height: 66px;
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

  .plain-login {
    display: none;
  }
}
</style>
