<script setup lang="ts">
import { nextTick, onMounted, onUnmounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { ArrowRightOutlined, ArrowUpOutlined, CheckOutlined } from '@ant-design/icons-vue'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { useLoginUserStore } from '@/stores/loginUser'
import { addApp, listGoodAppVoByPage, listMyAppVoByPage } from '@/api/appController'
import { getDeployUrl } from '@/config/env'
import AppCard from '@/components/AppCard.vue'
import heroImage from '@/assets/zerocode-hero.webp'
import studioPreview from '@/assets/zerocode-studio-preview.webp'

gsap.registerPlugin(ScrollTrigger)

const router = useRouter()
const loginUserStore = useLoginUserStore()
const pageRoot = ref<HTMLElement>()
const userPrompt = ref('')
const creating = ref(false)
const activeSignal = ref(0)
const myApps = ref<API.AppVO[]>([])
const featuredApps = ref<API.AppVO[]>([])

const myAppsPage = reactive({ current: 1, pageSize: 6, total: 0 })
const featuredAppsPage = reactive({ current: 1, pageSize: 6, total: 0 })

const promptIdeas = [
  {
    title: '个人作品集',
    copy: '为独立设计师创建一个强调视觉叙事的作品集，包含项目详情、关于页面与联系入口。',
  },
  {
    title: '产品落地页',
    copy: '为 AI 效率工具创建一个高转化落地页，包含功能对比、使用流程、定价与常见问题。',
  },
  {
    title: '内容网站',
    copy: '创建一个现代内容网站，包含文章列表、分类、搜索、详情页和作者信息，支持移动端。',
  },
]

const signalCards = [
  ['描述需求', '自然语言直接定义页面、风格和交互。'],
  ['实时生成', '流式查看推理进度与代码生成结果。'],
  ['继续修改', '选中页面元素，用对话完成局部调整。'],
]

const statement = ['构思', '设计', '代码', '预览', '部署', '现在', '在同一条', '创作链路里。']
let animationContext: gsap.Context | undefined
let signalTimer: number | undefined

const setPrompt = (prompt: string) => {
  userPrompt.value = prompt
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const handleComposerKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) {
    event.preventDefault()
    void createApp()
  }
}

const createApp = async () => {
  const prompt = userPrompt.value.trim()
  if (!prompt) {
    message.warning('先描述你想创建的网站')
    return
  }
  if (!loginUserStore.loginUser.id) {
    message.info('登录后即可开始生成')
    await router.push('/user/login')
    return
  }

  creating.value = true
  try {
    const res = await addApp({ initPrompt: prompt })
    if (res.data.code === 0 && res.data.data) {
      await router.push(`/app/chat/${String(res.data.data)}`)
      return
    }
    message.error(`创建失败：${res.data.message}`)
  } catch {
    message.error('创建请求未完成，请稍后重试')
  } finally {
    creating.value = false
  }
}

const loadMyApps = async () => {
  if (!loginUserStore.loginUser.id) return
  try {
    const res = await listMyAppVoByPage({
      pageNum: myAppsPage.current,
      pageSize: myAppsPage.pageSize,
      sortField: 'createTime',
      sortOrder: 'desc',
    })
    if (res.data.code === 0 && res.data.data) {
      myApps.value = res.data.data.records || []
      myAppsPage.total = Number(res.data.data.totalRow || 0)
    }
  } catch {
    myApps.value = []
  }
}

const loadFeaturedApps = async () => {
  try {
    const res = await listGoodAppVoByPage({
      pageNum: featuredAppsPage.current,
      pageSize: featuredAppsPage.pageSize,
      sortField: 'createTime',
      sortOrder: 'desc',
    })
    if (res.data.code === 0 && res.data.data) {
      featuredApps.value = res.data.data.records || []
      featuredAppsPage.total = Number(res.data.data.totalRow || 0)
    }
  } catch {
    featuredApps.value = []
  }
}

const viewChat = (appId: string | number | undefined) => {
  if (appId) router.push(`/app/chat/${appId}?view=1`)
}

const viewWork = (app: API.AppVO) => {
  if (app.deployKey) window.open(getDeployUrl(app.deployKey), '_blank', 'noopener,noreferrer')
}

onMounted(async () => {
  await Promise.all([loadMyApps(), loadFeaturedApps()])
  await nextTick()

  animationContext = gsap.context(() => {
    gsap.from('.hero-copy > *', {
      y: 28,
      opacity: 0,
      duration: 0.8,
      stagger: 0.1,
      ease: 'power3.out',
    })

    gsap.from('.hero-visual', {
      scale: 0.84,
      opacity: 0,
      duration: 1.25,
      ease: 'power3.out',
    })

    gsap.fromTo(
      '.statement-word',
      { opacity: 0.12 },
      {
        opacity: 1,
        stagger: 0.12,
        scrollTrigger: {
          trigger: '.statement',
          start: 'top 80%',
          end: 'bottom 35%',
          scrub: true,
        },
      },
    )

    const media = gsap.matchMedia()
    media.add('(min-width: 900px)', () => {
      ScrollTrigger.create({
        trigger: '.workflow-grid',
        start: 'top 130px',
        end: 'bottom bottom',
        pin: '.workflow-copy',
        pinSpacing: false,
      })
    })
  }, pageRoot.value)

  signalTimer = window.setInterval(() => {
    activeSignal.value = (activeSignal.value + 1) % signalCards.length
  }, 3200)
})

onUnmounted(() => {
  animationContext?.revert()
  if (signalTimer) window.clearInterval(signalTimer)
})
</script>

<template>
  <main ref="pageRoot" class="home-page">
    <section class="hero-section">
      <div class="hero-copy">
        <h1>一句话，<br />做出真正的网站。</h1>
        <p class="hero-lead">描述你的想法，实时生成、预览、编辑并发布。</p>

        <div class="composer">
          <a-textarea
            v-model:value="userPrompt"
            aria-label="网站需求描述"
            placeholder="做一个深圳城市探索网站，包含景点、美食和路线推荐"
            :auto-size="{ minRows: 3, maxRows: 7 }"
            :maxlength="1000"
            @keydown="handleComposerKeydown"
          />
          <div class="composer-footer">
            <span>网页</span>
            <a-button type="primary" :loading="creating" aria-label="开始生成" @click="createApp">
              生成网站 <ArrowUpOutlined />
            </a-button>
          </div>
        </div>

        <div class="prompt-shortcuts" aria-label="示例需求">
          <button v-for="idea in promptIdeas" :key="idea.title" type="button" @click="setPrompt(idea.copy)">
            {{ idea.title }} <ArrowRightOutlined />
          </button>
        </div>
      </div>

      <div class="hero-visual" aria-label="Zerocode 创作工作台预览">
        <div class="browser-chrome">
          <span></span><span></span><span></span>
          <div>app.zerocode.site</div>
        </div>
        <img :src="studioPreview" alt="Zerocode 对话生成与实时预览工作台" />
      </div>
    </section>

    <section class="capability-section content-shell">
      <div class="section-heading">
        <p class="eyebrow"><span></span> 完整创作链路</p>
        <h2>一个工作区，完成从构思到上线。</h2>
      </div>

      <div class="bento-grid">
        <article class="bento-card bento-main">
          <img :src="heroImage" alt="Zerocode 模块化创作界面抽象主视觉" />
          <div class="bento-overlay">
            <span>生成工作台</span>
            <h3>对话、预览与修改始终同步。</h3>
          </div>
        </article>
        <article class="bento-card bento-side acid-card">
          <span>可编辑</span>
          <h3>选中页面元素，直接描述修改。</h3>
          <CheckOutlined />
        </article>
        <article class="bento-card bento-side dark-card">
          <span>可交付</span>
          <h3>下载源码，或生成可访问链接。</h3>
          <div class="code-lines"><i></i><i></i><i></i></div>
        </article>
      </div>
    </section>

    <section class="statement content-shell" aria-label="产品价值">
      <span v-for="word in statement" :key="word" class="statement-word">{{ word }}</span>
    </section>

    <section class="workflow-section content-shell">
      <div class="workflow-grid">
        <div class="workflow-copy">
          <p class="eyebrow"><span></span> 生成过程</p>
          <h2>看得见的进度，随时可接管。</h2>
          <p>生成过程通过流式对话持续反馈。首版完成后，继续用自然语言调整结构、内容与视觉细节。</p>
        </div>
        <div class="workflow-rail">
          <article
            v-for="(item, index) in signalCards"
            :key="item[0]"
            :class="{ active: activeSignal === index }"
            @mouseenter="activeSignal = index"
          >
            <span>{{ ['输入', '生成', '微调'][index] }}</span>
            <div>
              <h3>{{ item[0] }}</h3>
              <p>{{ item[1] }}</p>
            </div>
          </article>
        </div>
      </div>
    </section>

    <section v-if="loginUserStore.loginUser.id" class="projects-section content-shell">
      <div class="section-heading horizontal">
        <div>
          <p class="eyebrow"><span></span> 最近项目</p>
          <h2>继续你的创作。</h2>
        </div>
        <span>{{ myAppsPage.total }} 个项目</span>
      </div>
      <div v-if="myApps.length" class="app-grid">
        <AppCard v-for="app in myApps" :key="app.id" :app="app" @view-chat="viewChat" @view-work="viewWork" />
      </div>
      <div v-else class="empty-projects">
        <p>你的第一个项目会出现在这里。</p>
        <button type="button" @click="scrollToTop">创建项目</button>
      </div>
      <a-pagination
        v-if="myAppsPage.total > myAppsPage.pageSize"
        v-model:current="myAppsPage.current"
        :page-size="myAppsPage.pageSize"
        :total="myAppsPage.total"
        :show-size-changer="false"
        @change="loadMyApps"
      />
    </section>

    <section v-if="featuredApps.length" class="projects-section featured content-shell">
      <div class="section-heading horizontal">
        <div>
          <p class="eyebrow"><span></span> 精选案例</p>
          <h2>看看 Zerocode 能做什么。</h2>
        </div>
      </div>
      <div class="app-grid">
        <AppCard
          v-for="app in featuredApps"
          :key="app.id"
          :app="app"
          featured
          @view-chat="viewChat"
          @view-work="viewWork"
        />
      </div>
    </section>

    <section class="final-cta content-shell">
      <p>准备好把想法变成页面了吗？</p>
      <h2>从一句清晰的描述开始。</h2>
      <button type="button" @click="scrollToTop">
        打开创作框 <ArrowUpOutlined />
      </button>
    </section>
  </main>
</template>

<style scoped>
.home-page {
  width: 100%;
  max-width: 100%;
  background:
    radial-gradient(circle at 78% 12%, rgba(141, 162, 255, 0.13), transparent 26%),
    var(--ink);
  color: var(--paper);
  overflow-x: hidden;
}

.content-shell,
.hero-section {
  width: min(1180px, calc(100% - 40px));
  margin: 0 auto;
}

.hero-section {
  padding: 170px 0 110px;
  text-align: center;
}

.hero-copy {
  position: relative;
  z-index: 2;
}

.eyebrow {
  margin: 0 0 22px;
  color: #b3b9b2;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

.eyebrow span {
  width: 8px;
  height: 8px;
  margin-right: 8px;
  border-radius: 50%;
  background: var(--acid);
  display: inline-block;
}

h1 {
  max-width: 1120px;
  margin: 0 auto;
  font-size: clamp(3.5rem, 8vw, 7.5rem);
  font-weight: 800;
  letter-spacing: -0.075em;
  line-height: 0.88;
}

.hero-lead {
  max-width: 720px;
  margin: 34px auto 0;
  color: #b7bdb6;
  font-size: clamp(1.05rem, 2vw, 1.28rem);
  line-height: 1.6;
}

.composer {
  max-width: 820px;
  margin: 42px auto 0;
  padding: 14px;
  border: 1px solid rgba(242, 240, 232, 0.22);
  border-radius: 22px;
  background: rgba(20, 24, 20, 0.86);
  box-shadow: 0 36px 100px rgba(0, 0, 0, 0.42);
  text-align: left;
}

.composer :deep(textarea.ant-input) {
  padding: 12px;
  border: 0 !important;
  background: transparent !important;
  box-shadow: none !important;
  color: var(--paper);
  font-size: 17px;
  line-height: 1.55;
  resize: none;
}

.composer-footer {
  padding: 10px 4px 0 12px;
  border-top: 1px solid var(--line);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
}

.composer-footer > span {
  color: #777e77;
  font-size: 12px;
}

.composer-footer :deep(.ant-btn) {
  height: 46px;
  padding: 0 20px;
  border-radius: 12px;
}

.prompt-shortcuts {
  margin-top: 18px;
  display: flex;
  justify-content: center;
  gap: 8px;
  flex-wrap: wrap;
}

.prompt-shortcuts button {
  padding: 9px 13px;
  border: 1px solid var(--line);
  border-radius: 999px;
  background: transparent;
  color: #aeb4ad;
  cursor: pointer;
  transition: 180ms ease;
}

.prompt-shortcuts button:hover {
  border-color: var(--acid);
  color: var(--paper);
}

.hero-visual {
  position: relative;
  min-height: 580px;
  margin-top: 76px;
  border: 1px solid var(--line);
  border-radius: 28px;
  background-position: center;
  background-size: cover;
  box-shadow: 0 50px 140px rgba(0, 0, 0, 0.52);
  overflow: hidden;
}

.hero-visual::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, rgba(11, 13, 12, 0.06), rgba(11, 13, 12, 0.34));
}

.visual-status {
  position: absolute;
  z-index: 2;
  right: 18px;
  bottom: 18px;
  left: 18px;
  padding: 15px 17px;
  border: 1px solid rgba(242, 240, 232, 0.18);
  border-radius: 14px;
  background: rgba(8, 10, 9, 0.76);
  backdrop-filter: blur(18px);
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  text-align: left;
}

.visual-status strong {
  margin-left: auto;
  color: var(--acid);
  letter-spacing: 0.14em;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--acid);
  box-shadow: 0 0 18px var(--acid);
}

.marquee {
  border-top: 1px solid var(--line);
  border-bottom: 1px solid var(--line);
  overflow: hidden;
}

.marquee-track {
  width: max-content;
  padding: 22px 0;
  color: var(--acid);
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 0.1em;
  animation: marquee 26s linear infinite;
}

@keyframes marquee {
  to { transform: translateX(-50%); }
}

.capability-section,
.workflow-section,
.projects-section {
  padding: 180px 0;
}

.section-heading {
  max-width: 760px;
  margin-bottom: 60px;
}

.section-heading.horizontal {
  max-width: none;
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 20px;
}

.section-heading h2,
.workflow-copy h2,
.final-cta h2 {
  margin: 0;
  font-size: clamp(2.7rem, 6vw, 5.5rem);
  letter-spacing: -0.065em;
  line-height: 0.95;
}

.section-heading.horizontal > span {
  color: var(--muted);
}

.bento-grid {
  min-height: 620px;
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  grid-template-rows: repeat(2, minmax(0, 1fr));
  grid-auto-flow: dense;
  gap: 12px;
}

.bento-card {
  position: relative;
  border: 1px solid var(--line);
  border-radius: 24px;
  overflow: hidden;
}

.bento-main {
  grid-column: span 3;
  grid-row: span 2;
}

.bento-main img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  filter: saturate(0.78) contrast(1.08);
  transition: transform 700ms ease;
}

.bento-main:hover img {
  transform: scale(1.05);
}

.bento-overlay {
  position: absolute;
  inset: auto 0 0;
  padding: 120px 28px 28px;
  background: linear-gradient(transparent, rgba(7, 9, 8, 0.94));
}

.bento-overlay span,
.bento-side > span {
  color: var(--muted);
  font-size: 13px;
}

.bento-overlay h3,
.bento-side h3 {
  max-width: 420px;
  margin: 10px 0 0;
  font-size: clamp(1.7rem, 3vw, 2.8rem);
  letter-spacing: -0.045em;
  line-height: 1.02;
}

.bento-side {
  grid-column: span 3;
  padding: 28px;
}

.acid-card {
  background: var(--acid);
  color: var(--ink);
}

.acid-card > span {
  color: #4b5d1c;
}

.acid-card :deep(svg) {
  position: absolute;
  right: 28px;
  bottom: 28px;
  font-size: 28px;
}

.dark-card {
  background: #171b17;
}

.code-lines {
  position: absolute;
  right: 28px;
  bottom: 28px;
  left: 28px;
  display: grid;
  gap: 7px;
}

.code-lines i {
  height: 5px;
  border-radius: 4px;
  background: rgba(242, 240, 232, 0.16);
}

.code-lines i:nth-child(2) { width: 72%; background: var(--cobalt); }
.code-lines i:nth-child(3) { width: 42%; }

.statement {
  padding: 90px 0 160px;
  font-size: clamp(3rem, 7vw, 7rem);
  font-weight: 800;
  letter-spacing: -0.07em;
  line-height: 0.98;
}

.statement-word {
  margin-right: 0.18em;
}

.workflow-grid {
  position: relative;
  min-height: 820px;
  display: grid;
  grid-template-columns: 0.85fr 1.15fr;
  gap: 9vw;
}

.workflow-copy {
  align-self: start;
}

.workflow-copy p:last-child {
  max-width: 520px;
  color: var(--muted);
  font-size: 18px;
  line-height: 1.65;
}

.workflow-rail {
  display: grid;
  gap: 18px;
}

.workflow-rail article {
  min-height: 230px;
  padding: 28px;
  border: 1px solid var(--line);
  border-radius: 22px;
  background: #111411;
  display: flex;
  gap: 28px;
  opacity: 0.45;
  transform: scale(0.97);
  transition: 420ms ease;
}

.workflow-rail article.active,
.workflow-rail article:hover {
  border-color: rgba(199, 255, 66, 0.48);
  opacity: 1;
  transform: scale(1);
}

.workflow-rail article > span {
  color: var(--acid);
  font-size: 13px;
}

.workflow-rail h3 {
  margin: 0 0 16px;
  font-size: 30px;
}

.workflow-rail p {
  margin: 0;
  color: var(--muted);
  font-size: 17px;
  line-height: 1.6;
}

.app-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.empty-projects {
  min-height: 260px;
  padding: 30px;
  border: 1px dashed rgba(242, 240, 232, 0.22);
  border-radius: 22px;
  display: grid;
  place-content: center;
  justify-items: center;
  color: var(--muted);
}

.empty-projects button,
.final-cta button {
  border: 0;
  border-radius: 12px;
  background: var(--acid);
  color: var(--ink);
  cursor: pointer;
  font-weight: 800;
}

.empty-projects button { padding: 11px 16px; }

.final-cta {
  margin-bottom: 110px;
  padding: 80px;
  border-radius: 30px;
  background: var(--paper);
  color: var(--ink);
}

.final-cta p {
  margin: 0 0 18px;
  color: #596058;
}

.final-cta button {
  margin-top: 36px;
  padding: 16px 20px;
  background: var(--ink);
  color: var(--paper);
}

@media (max-width: 900px) {
  .hero-section { padding-top: 130px; }
  .hero-visual { min-height: 440px; }
  .capability-section,
  .workflow-section,
  .projects-section { padding: 120px 0; }
  .workflow-grid { min-height: auto; grid-template-columns: 1fr; gap: 50px; }
  .app-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}

@media (max-width: 680px) {
  .content-shell,
  .hero-section { width: calc(100% - 24px); }
  h1 { font-size: clamp(3.2rem, 16vw, 5.2rem); }
  .hero-lead { font-size: 1rem; }
  .composer-footer { align-items: stretch; flex-direction: column; }
  .composer-footer > span { display: none; }
  .composer-footer :deep(.ant-btn) { width: 100%; }
  .hero-visual { min-height: 330px; margin-top: 46px; }
  .visual-status > span:nth-child(2) { display: none; }
  .bento-grid { min-height: auto; grid-template-columns: 1fr; grid-template-rows: none; }
  .bento-main,
  .bento-side { grid-column: span 1; grid-row: span 1; }
  .bento-main { min-height: 430px; }
  .bento-side { min-height: 230px; }
  .statement { padding: 60px 0 100px; }
  .section-heading.horizontal { align-items: flex-start; flex-direction: column; }
  .app-grid { grid-template-columns: 1fr; }
  .final-cta { margin-bottom: 70px; padding: 42px 24px; }
}

@media (prefers-reduced-motion: reduce) {
  .marquee-track { animation: none; }
  * { scroll-behavior: auto !important; }
}

/* Lovable-inspired light product language, translated to the Zerocode brand. */
.home-page {
  --ink: #11130f;
  --paper: #f7f8f4;
  --muted: #6d736b;
  --line: #dfe2d8;
  --acid: #c8f43d;
  --acid-deep: #a9db1e;
  --cobalt: #727970;
  background:
    radial-gradient(circle at 86% 12%, rgba(200, 244, 61, 0.09), transparent 24%),
    #f7f8f4;
  color: #11130f;
}

.content-shell,
.hero-section {
  width: min(1440px, calc(100% - 64px));
}

.hero-section {
  position: relative;
  min-height: 930px;
  padding: 188px 0 110px;
  text-align: left;
}

.hero-copy {
  width: min(770px, 56vw);
}

h1 {
  max-width: 770px;
  margin: 0;
  font-size: clamp(3.8rem, 5.2vw, 5.4rem);
  font-weight: 760;
  letter-spacing: -0.07em;
  line-height: 0.98;
}

.hero-lead {
  max-width: 560px;
  margin: 28px 0 0;
  color: #747a72;
  font-size: clamp(1.05rem, 1.5vw, 1.35rem);
  line-height: 1.55;
}

.composer {
  max-width: 720px;
  margin: 42px 0 0;
  padding: 14px;
  border-color: rgba(169, 219, 30, 0.72);
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: 0 24px 70px rgba(54, 64, 39, 0.08);
}

.composer :deep(textarea.ant-input) {
  min-height: 92px;
  color: #11130f !important;
}

.composer :deep(textarea.ant-input::placeholder) {
  color: #737970 !important;
}

.composer-footer {
  border-top-color: #eceee8;
}

.composer-footer > span {
  min-width: 72px;
  padding: 8px 12px;
  border: 1px solid #e1e4dc;
  border-radius: 999px;
  color: #4e544c;
  font-weight: 700;
  text-align: center;
}

.composer-footer :deep(.ant-btn) {
  border-radius: 999px;
}

.prompt-shortcuts {
  justify-content: flex-start;
}

.prompt-shortcuts button {
  border-color: #dfe2d8;
  color: #656b63;
}

.prompt-shortcuts button:hover {
  border-color: #a9db1e;
  color: #11130f;
}

.hero-visual {
  position: absolute;
  right: -110px;
  bottom: 56px;
  width: min(760px, 53vw);
  min-height: 0;
  margin: 0;
  border-color: #dfe2d8;
  border-radius: 24px;
  background: #fff;
  box-shadow: 0 40px 110px rgba(54, 64, 39, 0.13);
  transform: rotate(-1.2deg);
}

.hero-visual::after {
  display: none;
}

.hero-visual img {
  display: block;
  width: 100%;
  height: auto;
}

.browser-chrome {
  height: 46px;
  padding: 0 14px;
  border-bottom: 1px solid #eceee8;
  display: flex;
  align-items: center;
  gap: 7px;
}

.browser-chrome > span {
  width: 9px;
  height: 9px;
  border-radius: 50%;
  background: #d6d9d1;
}

.browser-chrome > span:first-child {
  background: #c8f43d;
}

.browser-chrome > div {
  min-width: 220px;
  margin-left: 9px;
  padding: 7px 14px;
  border-radius: 999px;
  background: #f3f4f0;
  color: #858b82;
  font-size: 11px;
}

.capability-section,
.workflow-section,
.projects-section {
  padding: 150px 0;
}

.section-heading h2,
.workflow-copy h2,
.final-cta h2 {
  color: #11130f;
}

.eyebrow {
  color: #737970;
}

.eyebrow span {
  background: #c8f43d;
}

.bento-card,
.workflow-rail article,
.app-card {
  border-color: #dfe2d8;
  background: #fff;
}

.dark-card {
  background: #151713;
  color: #f7f8f4;
}

.statement {
  color: #11130f;
}

.workflow-copy p:last-child,
.workflow-rail p,
.section-heading.horizontal > span {
  color: #6d736b;
}

.workflow-rail article.active,
.workflow-rail article:hover {
  border-color: rgba(169, 219, 30, 0.8);
  box-shadow: 0 20px 55px rgba(54, 64, 39, 0.08);
}

.empty-projects {
  border-color: #d4d8ce;
  color: #6d736b;
}

.final-cta {
  background: #c8f43d;
  color: #11130f;
}

.final-cta p {
  color: #4d561f;
}

@media (max-width: 1050px) {
  .hero-section {
    min-height: auto;
    padding-top: 150px;
  }

  .hero-copy {
    width: 100%;
  }

  .hero-visual {
    position: relative;
    right: auto;
    bottom: auto;
    width: 100%;
    margin-top: 64px;
    transform: none;
  }
}

@media (max-width: 680px) {
  .content-shell,
  .hero-section {
    width: calc(100% - 28px);
  }

  .hero-section {
    padding-top: 122px;
  }

  h1 {
    font-size: clamp(2.75rem, 11.5vw, 3.4rem);
  }

  .composer {
    margin-top: 30px;
  }

  .composer-footer {
    align-items: center;
    flex-direction: row;
  }

  .composer-footer > span {
    display: inline-block;
  }

  .composer-footer :deep(.ant-btn) {
    width: auto;
  }

  .prompt-shortcuts {
    flex-wrap: nowrap;
    overflow-x: auto;
  }

  .prompt-shortcuts button {
    white-space: nowrap;
  }

  .hero-visual {
    min-height: 0;
    margin-top: 42px;
  }

  .browser-chrome > div {
    min-width: 0;
    flex: 1;
  }
}
</style>
