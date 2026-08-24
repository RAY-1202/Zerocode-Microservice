<script setup lang="ts">
import { reactive, ref } from 'vue'
import { message } from 'ant-design-vue'
import { ArrowRightOutlined } from '@ant-design/icons-vue'
import { useRoute, useRouter } from 'vue-router'
import { useLoginUserStore } from '@/stores/loginUser'
import { login } from '@/api/userController'

const route = useRoute()
const router = useRouter()
const loginUserStore = useLoginUserStore()
const submitting = ref(false)
const formState = reactive<API.UserLoginRequest>({ userAccount: '', userPassword: '' })

const handleSubmit = async (values: API.UserLoginRequest) => {
  submitting.value = true
  try {
    const res = await login(values)
    if (res.data.code === 0 && res.data.data) {
      await loginUserStore.fetchLoginUser()
      message.success('欢迎回来')
      const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/'
      const target = redirect.startsWith('/') && !redirect.startsWith('//') ? redirect : '/'
      await router.replace(target)
      return
    }
    message.error(`登录失败：${res.data.message}`)
  } catch {
    message.error('登录服务暂时不可用')
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <main class="auth-page">
    <section class="auth-story">
      <RouterLink class="auth-brand" to="/">Zerocode</RouterLink>
      <div>
        <p>AI 原生创作空间</p>
        <h1>继续把你的想法，变成可访问的作品。</h1>
      </div>
      <span>对话生成　实时预览　继续修改</span>
    </section>

    <section class="auth-form-panel">
      <div class="auth-form-shell">
        <p class="kicker">欢迎回来</p>
        <h2>登录你的工作区</h2>
        <p class="form-copy">输入账号和密码，继续最近的创作。</p>

        <a-form :model="formState" layout="vertical" autocomplete="on" @finish="handleSubmit">
          <a-form-item label="账号" name="userAccount" :rules="[{ required: true, message: '请输入账号' }]">
            <a-input v-model:value="formState.userAccount" size="large" placeholder="你的账号" autocomplete="username" />
          </a-form-item>
          <a-form-item
            label="密码"
            name="userPassword"
            :rules="[{ required: true, message: '请输入密码' }, { min: 8, message: '密码至少 8 位' }]"
          >
            <a-input-password
              v-model:value="formState.userPassword"
              size="large"
              placeholder="至少 8 位"
              autocomplete="current-password"
            />
          </a-form-item>
          <a-button class="submit-button" type="primary" html-type="submit" :loading="submitting">
            登录并继续 <ArrowRightOutlined />
          </a-button>
        </a-form>

        <p class="switch-auth">第一次来到 Zerocode？<RouterLink to="/user/register">创建账号</RouterLink></p>
      </div>
    </section>
  </main>
</template>

<style scoped>
.auth-page {
  min-height: 100vh;
  background: var(--ink);
  display: grid;
  grid-template-columns: 1.05fr 0.95fr;
}

.auth-story {
  min-height: 100vh;
  padding: 48px clamp(32px, 6vw, 90px);
  background:
    radial-gradient(circle at 22% 22%, rgba(199, 255, 66, 0.2), transparent 24%),
    linear-gradient(150deg, #171d15, #0b0d0c 68%);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.auth-brand {
  color: var(--paper);
  font-size: 22px;
  font-weight: 800;
  text-decoration: none;
}

.auth-story p,
.auth-story > span {
  color: var(--acid);
  font-size: 13px;
  letter-spacing: 0.12em;
}

.auth-story h1 {
  max-width: 760px;
  margin: 18px 0 0;
  font-size: clamp(3rem, 6vw, 6.5rem);
  letter-spacing: -0.07em;
  line-height: 0.92;
}

.auth-form-panel {
  padding: 130px 32px 60px;
  display: grid;
  place-items: center;
}

.auth-form-shell {
  width: min(440px, 100%);
}

.kicker {
  margin: 0 0 12px;
  color: var(--acid);
  font-weight: 700;
}

h2 {
  margin: 0;
  font-size: clamp(2.5rem, 5vw, 4rem);
  letter-spacing: -0.06em;
}

.form-copy {
  margin: 14px 0 36px;
  color: var(--muted);
}

.submit-button {
  width: 100%;
  height: 50px;
  margin-top: 8px;
  border-radius: 12px;
}

.switch-auth {
  margin-top: 24px;
  color: var(--muted);
  text-align: center;
}

.switch-auth a {
  color: var(--paper);
  font-weight: 700;
}

@media (max-width: 820px) {
  .auth-page { grid-template-columns: 1fr; }
  .auth-story { min-height: 42vh; padding: 32px 24px; }
  .auth-story > span { display: none; }
  .auth-form-panel { padding: 56px 24px 80px; }
}
</style>
