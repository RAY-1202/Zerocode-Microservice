<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { ArrowRightOutlined } from '@ant-design/icons-vue'
import { register } from '@/api/userController'

const router = useRouter()
const submitting = ref(false)
const formState = reactive<API.UserRegisterRequest>({ userAccount: '', userPassword: '', checkPassword: '' })

const validateCheckPassword = (_rule: unknown, value: string) => {
  if (value && value !== formState.userPassword) return Promise.reject(new Error('两次密码输入不一致'))
  return Promise.resolve()
}

const handleSubmit = async (values: API.UserRegisterRequest) => {
  submitting.value = true
  try {
    const res = await register(values)
    if (res.data.code === 0) {
      message.success('账号已创建，请登录')
      await router.replace('/user/login')
      return
    }
    message.error(`注册失败：${res.data.message}`)
  } catch {
    message.error('注册服务暂时不可用')
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
        <p>创建你的工作区</p>
        <h1>今天的想法，可以今天就上线。</h1>
      </div>
      <span>自然语言输入　源码可下载　结果可部署</span>
    </section>

    <section class="auth-form-panel">
      <div class="auth-form-shell">
        <p class="kicker">免费开始</p>
        <h2>创建 Zerocode 账号</h2>
        <p class="form-copy">设置账号与密码，打开你的第一个创作空间。</p>

        <a-form :model="formState" layout="vertical" autocomplete="on" @finish="handleSubmit">
          <a-form-item label="账号" name="userAccount" :rules="[{ required: true, message: '请输入账号' }]">
            <a-input v-model:value="formState.userAccount" size="large" placeholder="你的账号" autocomplete="username" />
          </a-form-item>
          <a-form-item
            label="密码"
            name="userPassword"
            :rules="[{ required: true, message: '请输入密码' }, { min: 8, message: '密码至少 8 位' }]"
          >
            <a-input-password v-model:value="formState.userPassword" size="large" placeholder="至少 8 位" autocomplete="new-password" />
          </a-form-item>
          <a-form-item
            label="确认密码"
            name="checkPassword"
            :rules="[{ required: true, message: '请再次输入密码' }, { validator: validateCheckPassword, trigger: 'blur' }]"
          >
            <a-input-password v-model:value="formState.checkPassword" size="large" placeholder="再次输入密码" autocomplete="new-password" />
          </a-form-item>
          <a-button class="submit-button" type="primary" html-type="submit" :loading="submitting">
            创建账号 <ArrowRightOutlined />
          </a-button>
        </a-form>

        <p class="switch-auth">已经有账号？<RouterLink to="/user/login">直接登录</RouterLink></p>
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
    radial-gradient(circle at 22% 22%, rgba(141, 162, 255, 0.22), transparent 26%),
    linear-gradient(150deg, #161822, #0b0d0c 68%);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.auth-brand { color: var(--paper); font-size: 22px; font-weight: 800; text-decoration: none; }
.auth-story p,
.auth-story > span { color: var(--acid); font-size: 13px; letter-spacing: 0.12em; }
.auth-story h1 { max-width: 760px; margin: 18px 0 0; font-size: clamp(3rem, 6vw, 6.5rem); letter-spacing: -0.07em; line-height: 0.92; }
.auth-form-panel { padding: 130px 32px 60px; display: grid; place-items: center; }
.auth-form-shell { width: min(440px, 100%); }
.kicker { margin: 0 0 12px; color: var(--acid); font-weight: 700; }
h2 { margin: 0; font-size: clamp(2.5rem, 5vw, 4rem); letter-spacing: -0.06em; line-height: 0.98; }
.form-copy { margin: 14px 0 36px; color: var(--muted); }
.submit-button { width: 100%; height: 50px; margin-top: 8px; border-radius: 12px; }
.switch-auth { margin-top: 24px; color: var(--muted); text-align: center; }
.switch-auth a { color: var(--paper); font-weight: 700; }

@media (max-width: 820px) {
  .auth-page { grid-template-columns: 1fr; }
  .auth-story { min-height: 42vh; padding: 32px 24px; }
  .auth-story > span { display: none; }
  .auth-form-panel { padding: 56px 24px 80px; }
}
</style>
