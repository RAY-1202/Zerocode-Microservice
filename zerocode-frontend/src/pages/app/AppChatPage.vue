<template>
  <div id="appChatPage">
    <header class="studio-header">
      <div class="studio-identity">
        <RouterLink class="studio-brand" to="/" aria-label="返回 Zerocode 首页">
          <span class="studio-mark" aria-hidden="true"><i></i><i></i></span>
          <strong>Zerocode</strong>
        </RouterLink>
        <span class="header-divider"></span>
        <button class="project-name" type="button" @click="showAppDetail">
          <span>我的项目</span>
          <b>/</b>
          {{ appInfo?.appName || '网站生成器' }}
        </button>
      </div>

      <div class="workspace-switcher" aria-label="工作区模式">
        <button class="active" type="button">预览</button>
        <button type="button" disabled>代码</button>
        <button type="button" disabled>对比</button>
      </div>

      <div class="studio-actions">
        <span v-if="appInfo?.codeGenType" class="mode-label">
          {{ formatCodeGenType(appInfo.codeGenType) }}
        </span>
        <a-button @click="downloadCode" :loading="downloading" :disabled="!isOwner">
          <template #icon><DownloadOutlined /></template>
          下载
        </a-button>
        <a-button class="deploy-button" @click="deployApp" :loading="deploying">
          <template #icon><CloudUploadOutlined /></template>
          部署
        </a-button>
      </div>
    </header>

    <main class="studio-main">
      <section class="chat-section" aria-label="生成对话">
        <div class="panel-heading">
          <div>
            <p>和 Zerocode 一起构建</p>
            <span>{{ isGenerating ? '正在生成你的页面' : '描述需求，继续完善结果' }}</span>
          </div>
          <button type="button" aria-label="应用详情" @click="showAppDetail"><InfoCircleOutlined /></button>
        </div>

        <div ref="messagesContainer" class="messages-container">
          <div v-if="hasMoreHistory" class="load-more-container">
            <a-button type="link" size="small" :loading="loadingHistory" @click="loadMoreHistory">
              加载更多历史消息
            </a-button>
          </div>
          <div v-for="(message, index) in messages" :key="index" class="message-item">
            <div v-if="message.type === 'user'" class="user-message">
              <div class="message-avatar">
                <a-avatar :src="loginUserStore.loginUser.userAvatar" />
              </div>
              <div class="message-content">{{ message.content }}</div>
            </div>
            <div v-else class="ai-message">
              <div class="message-avatar ai-avatar"><span>Z</span></div>
              <div class="message-content">
                <MarkdownRenderer v-if="message.content" :content="message.content" />
                <div v-if="message.loading" class="loading-indicator">
                  <a-spin size="small" />
                  <span>正在整理页面结构</span>
                </div>
              </div>
            </div>
          </div>

          <div v-if="!messages.length && !loadingHistory" class="empty-conversation">
            <span>Z</span>
            <h2>从一句清晰的描述开始。</h2>
            <p>告诉我网站的用途、内容和视觉方向。</p>
          </div>
        </div>

        <div class="input-container">
          <div class="input-wrapper">
            <a-tooltip v-if="!isOwner" title="仅作品所有者可以继续修改" placement="top">
              <a-textarea
                v-model:value="userInput"
                :placeholder="getInputPlaceholder()"
                :rows="3"
                :maxlength="1000"
                :disabled="isGenerating || !isOwner"
                @keydown.enter.prevent="sendMessage"
              />
            </a-tooltip>
            <a-textarea
              v-else
              v-model:value="userInput"
              :placeholder="getInputPlaceholder()"
              :rows="3"
              :maxlength="1000"
              :disabled="isGenerating"
              @keydown.enter.prevent="sendMessage"
            />
            <div class="input-actions">
              <a-button type="primary" :loading="isGenerating" :disabled="!isOwner" @click="sendMessage">
                <template #icon><SendOutlined /></template>
              </a-button>
            </div>
          </div>
        </div>
      </section>

      <section class="preview-section" aria-label="实时预览">
        <div class="preview-toolbar">
          <div class="browser-address">
            <span class="browser-dots" aria-hidden="true"><i></i><i></i><i></i></span>
            <span>{{ previewDisplayUrl }}</span>
          </div>
          <div class="viewport-controls" aria-label="预览尺寸">
            <button
              v-for="option in viewportOptions"
              :key="option.value"
              type="button"
              :class="{ active: previewViewport === option.value }"
              :aria-label="option.label"
              @click="previewViewport = option.value"
            >
              <component :is="option.icon" />
            </button>
          </div>
          <span class="zoom-label">100%</span>
          <button v-if="previewUrl" class="toolbar-icon" type="button" aria-label="在新窗口打开" @click="openInNewTab">
            <ExportOutlined />
          </button>
        </div>

        <div class="preview-content">
          <div v-if="!previewUrl && !isGenerating" class="preview-placeholder">
            <CodeOutlined class="placeholder-icon" />
            <p>网站生成完成后会在这里实时呈现</p>
          </div>
          <div v-else-if="isGenerating" class="preview-loading">
            <a-spin size="large" />
            <p>正在生成网站</p>
          </div>
          <div v-else class="preview-stage" :class="`viewport-${previewViewport}`">
            <iframe
              :src="previewUrl"
              class="preview-iframe"
              frameborder="0"
              title="生成网站预览"
              @load="onIframeLoad"
            ></iframe>
          </div>
        </div>
      </section>

      <aside class="inspector-section" aria-label="页面编辑器">
        <div class="inspector-block page-block">
          <h2>页面</h2>
          <button class="page-row active" type="button"><CodeOutlined /> 当前页面</button>
        </div>
        <div class="inspector-block selection-block">
          <h2>选择元素</h2>
          <template v-if="selectedElementInfo">
            <div class="selected-summary">
              <strong>{{ selectedElementInfo.tagName.toLowerCase() }}</strong>
              <span v-if="selectedElementInfo.textContent">
                {{ selectedElementInfo.textContent.substring(0, 60) }}
              </span>
              <code>{{ selectedElementInfo.selector }}</code>
            </div>
            <button class="clear-selection" type="button" @click="clearSelectedElement">清除选择</button>
          </template>
          <p v-else>进入编辑模式后，在预览中选择元素，可直接修改内容与样式。</p>
          <button
            v-if="isOwner && previewUrl"
            class="edit-button"
            :class="{ active: isEditMode }"
            type="button"
            @click="toggleEditMode"
          >
            <EditOutlined />
            {{ isEditMode ? '退出编辑模式' : '进入编辑模式' }}
          </button>
        </div>
      </aside>
    </main>

    <AppDetailModal
      v-model:open="appDetailVisible"
      :app="appInfo"
      :show-actions="isOwner || isAdmin"
      @edit="editApp"
      @delete="deleteApp"
    />
    <DeploySuccessModal
      v-model:open="deployModalVisible"
      :deploy-url="deployUrl"
      @open-site="openDeployedSite"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick, onUnmounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { useLoginUserStore } from '@/stores/loginUser'
import {
  getAppVoById,
  deployApp as deployAppApi,
  deleteApp as deleteAppApi,
} from '@/api/appController'
import { listAppChatHistory } from '@/api/chatHistoryController'
import { CodeGenTypeEnum, formatCodeGenType } from '@/utils/codeGenTypes'
import request from '@/request'

import MarkdownRenderer from '@/components/MarkdownRenderer.vue'
import AppDetailModal from '@/components/AppDetailModal.vue'
import DeploySuccessModal from '@/components/DeploySuccessModal.vue'
import { API_BASE_URL, getStaticPreviewUrl } from '@/config/env'
import { VisualEditor, type ElementInfo } from '@/utils/visualEditor'

import {
  CloudUploadOutlined,
  SendOutlined,
  ExportOutlined,
  InfoCircleOutlined,
  DownloadOutlined,
  EditOutlined,
  CodeOutlined,
  DesktopOutlined,
  TabletOutlined,
  MobileOutlined,
} from '@ant-design/icons-vue'

const route = useRoute()
const router = useRouter()
const loginUserStore = useLoginUserStore()

// 应用信息
const appInfo = ref<API.AppVO>()
const appId = ref<any>()

// 对话相关
interface Message {
  type: 'user' | 'ai'
  content: string
  loading?: boolean
  createTime?: string
}

const messages = ref<Message[]>([])
const userInput = ref('')
const isGenerating = ref(false)
const messagesContainer = ref<HTMLElement>()

// 对话历史相关
const loadingHistory = ref(false)
const hasMoreHistory = ref(false)
const lastCreateTime = ref<string>()
const historyLoaded = ref(false)

// 预览相关
const previewUrl = ref('')
const previewReady = ref(false)
const previewViewport = ref<'desktop' | 'tablet' | 'mobile'>('desktop')
const viewportOptions = [
  { value: 'desktop' as const, label: '桌面预览', icon: DesktopOutlined },
  { value: 'tablet' as const, label: '平板预览', icon: TabletOutlined },
  { value: 'mobile' as const, label: '手机预览', icon: MobileOutlined },
]
const previewDisplayUrl = computed(() => {
  if (!previewUrl.value) return '等待生成预览'
  try {
    const url = new URL(previewUrl.value, window.location.origin)
    return `${url.host}${url.pathname}`
  } catch {
    return previewUrl.value
  }
})

// 部署相关
const deploying = ref(false)
const deployModalVisible = ref(false)
const deployUrl = ref('')

// 下载相关
const downloading = ref(false)

// 可视化编辑相关
const isEditMode = ref(false)
const selectedElementInfo = ref<ElementInfo | null>(null)
const visualEditor = new VisualEditor({
  onElementSelected: (elementInfo: ElementInfo) => {
    selectedElementInfo.value = elementInfo
  },
})

// 权限相关
const isOwner = computed(() => {
  return appInfo.value?.userId === loginUserStore.loginUser.id
})

const isAdmin = computed(() => {
  return loginUserStore.loginUser.userRole === 'admin'
})

// 应用详情相关
const appDetailVisible = ref(false)

// 显示应用详情
const showAppDetail = () => {
  appDetailVisible.value = true
}

// 加载对话历史
const loadChatHistory = async (isLoadMore = false) => {
  if (!appId.value || loadingHistory.value) return
  loadingHistory.value = true
  try {
    const params: API.listAppChatHistoryParams = {
      appId: appId.value,
      pageSize: 10,
    }
    // 如果是加载更多，传递最后一条消息的创建时间作为游标
    if (isLoadMore && lastCreateTime.value) {
      params.lastCreateTime = lastCreateTime.value
    }
    const res = await listAppChatHistory(params)
    if (res.data.code === 0 && res.data.data) {
      const chatHistories = res.data.data.records || []
      if (chatHistories.length > 0) {
        // 将对话历史转换为消息格式，并按时间正序排列（老消息在前）
        const historyMessages: Message[] = chatHistories
          .map((chat) => ({
            type: (chat.messageType === 'user' ? 'user' : 'ai') as 'user' | 'ai',
            content: chat.message || '',
            createTime: chat.createTime,
          }))
          .reverse() // 反转数组，让老消息在前
        if (isLoadMore) {
          // 加载更多时，将历史消息添加到开头
          messages.value.unshift(...historyMessages)
        } else {
          // 初始加载，直接设置消息列表
          messages.value = historyMessages
        }
        // 更新游标
        lastCreateTime.value = chatHistories[chatHistories.length - 1]?.createTime
        // 检查是否还有更多历史
        hasMoreHistory.value = chatHistories.length === 10
      } else {
        hasMoreHistory.value = false
      }
      historyLoaded.value = true
    }
  } catch (error) {
    console.error('加载对话历史失败：', error)
    message.error('加载对话历史失败')
  } finally {
    loadingHistory.value = false
  }
}

// 加载更多历史消息
const loadMoreHistory = async () => {
  await loadChatHistory(true)
}

// 获取应用信息
const fetchAppInfo = async () => {
  const id = route.params.id as string
  if (!id) {
    message.error('应用ID不存在')
    router.push('/')
    return
  }

  appId.value = id

  try {
    const res = await getAppVoById({ id: id as unknown as number })
    if (res.data.code === 0 && res.data.data) {
      appInfo.value = res.data.data

      // 先加载对话历史
      await loadChatHistory()
      // 如果有至少2条对话记录，展示对应的网站
      if (messages.value.length >= 2) {
        updatePreview()
      }
      // 检查是否需要自动发送初始提示词
      // 只有在是自己的应用且没有对话历史时才自动发送
      if (
        appInfo.value.initPrompt &&
        isOwner.value &&
        messages.value.length === 0 &&
        historyLoaded.value
      ) {
        await sendInitialMessage(appInfo.value.initPrompt)
      }
    } else {
      message.error('获取应用信息失败')
      router.push('/')
    }
  } catch (error) {
    console.error('获取应用信息失败：', error)
    message.error('获取应用信息失败')
    router.push('/')
  }
}

// 发送初始消息
const sendInitialMessage = async (prompt: string) => {
  // 添加用户消息
  messages.value.push({
    type: 'user',
    content: prompt,
  })

  // 添加AI消息占位符
  const aiMessageIndex = messages.value.length
  messages.value.push({
    type: 'ai',
    content: '',
    loading: true,
  })

  await nextTick()
  scrollToBottom()

  // 开始生成
  isGenerating.value = true
  await generateCode(prompt, aiMessageIndex)
}

// 发送消息
const sendMessage = async () => {
  if (!userInput.value.trim() || isGenerating.value) {
    return
  }

  let message = userInput.value.trim()
  // 如果有选中的元素，将元素信息添加到提示词中
  if (selectedElementInfo.value) {
    let elementContext = `\n\n选中元素信息：`
    if (selectedElementInfo.value.pagePath) {
      elementContext += `\n- 页面路径: ${selectedElementInfo.value.pagePath}`
    }
    elementContext += `\n- 标签: ${selectedElementInfo.value.tagName.toLowerCase()}\n- 选择器: ${selectedElementInfo.value.selector}`
    if (selectedElementInfo.value.textContent) {
      elementContext += `\n- 当前内容: ${selectedElementInfo.value.textContent.substring(0, 100)}`
    }
    message += elementContext
  }
  userInput.value = ''
  // 添加用户消息（包含元素信息）
  messages.value.push({
    type: 'user',
    content: message,
  })

  // 发送消息后，清除选中元素并退出编辑模式
  if (selectedElementInfo.value) {
    clearSelectedElement()
    if (isEditMode.value) {
      toggleEditMode()
    }
  }

  // 添加AI消息占位符
  const aiMessageIndex = messages.value.length
  messages.value.push({
    type: 'ai',
    content: '',
    loading: true,
  })

  await nextTick()
  scrollToBottom()

  // 开始生成
  isGenerating.value = true
  await generateCode(message, aiMessageIndex)
}

// 生成代码 - 使用 EventSource 处理流式响应
const generateCode = async (userMessage: string, aiMessageIndex: number) => {
  let eventSource: EventSource | null = null
  let streamCompleted = false

  try {
    // 获取 axios 配置的 baseURL
    const baseURL = request.defaults.baseURL || API_BASE_URL

    // 构建URL参数
    const params = new URLSearchParams({
      appId: appId.value || '',
      message: userMessage,
    })

    const url = `${baseURL}/app/chat/gen/code?${params}`

    // 创建 EventSource 连接
    eventSource = new EventSource(url, {
      withCredentials: true,
    })

    let fullContent = ''


    // 处理接收到的消息
    eventSource.onmessage = function (event) {
      if (streamCompleted) return

      try {
        // 解析JSON包装的数据
        const parsed = JSON.parse(event.data)
        const content = parsed.d

        // 拼接内容
        if (content !== undefined && content !== null) {
          fullContent += content
          messages.value[aiMessageIndex].content = fullContent
          messages.value[aiMessageIndex].loading = false
          scrollToBottom()
        }
      } catch (error) {
        console.error('解析消息失败:', error)
        handleError(error, aiMessageIndex)
      }
    }

    // 处理done事件
    eventSource.addEventListener('done', function () {
      if (streamCompleted) return

      streamCompleted = true
      isGenerating.value = false
      eventSource?.close()

      // 延迟更新预览，确保后端已完成处理
      setTimeout(async () => {
        await fetchAppInfo()
        updatePreview()
      }, 1000)
    })

    eventSource.addEventListener('business-error', function (event: MessageEvent) {
      if (streamCompleted) return

      try {
        const errorData = JSON.parse(event.data)
        console.error('SSE业务错误事件:', errorData)

        // 显示具体的错误信息
        const errorMessage = errorData.message || '生成过程中出现错误'
        messages.value[aiMessageIndex].content = errorMessage
        messages.value[aiMessageIndex].loading = false
        message.error(errorMessage)

        streamCompleted = true
        isGenerating.value = false
        eventSource?.close()
      } catch (parseError) {
        console.error('解析错误事件失败:', parseError, '原始数据:', event.data)
        handleError(new Error('服务器返回错误'), aiMessageIndex)
      }
    })

    // 处理错误
    eventSource.onerror = function () {
      if (streamCompleted || !isGenerating.value) return
      // 检查是否是正常的连接关闭
      if (eventSource?.readyState === EventSource.CONNECTING) {
        streamCompleted = true
        isGenerating.value = false
        eventSource?.close()

        setTimeout(async () => {
          await fetchAppInfo()
          updatePreview()
        }, 1000)
      } else {
        handleError(new Error('SSE连接错误'), aiMessageIndex)
      }
    }
  } catch (error) {
    console.error('创建 EventSource 失败：', error)
    handleError(error, aiMessageIndex)
  }
}

// 错误处理函数
const handleError = (error: unknown, aiMessageIndex: number) => {
  console.error('生成代码失败：', error)
  messages.value[aiMessageIndex].content = '抱歉，生成过程中出现了错误，请重试。'
  messages.value[aiMessageIndex].loading = false
  message.error('生成失败，请重试')
  isGenerating.value = false
}

// 更新预览
const updatePreview = () => {
  if (appId.value) {
    const codeGenType = appInfo.value?.codeGenType || CodeGenTypeEnum.HTML
    const newPreviewUrl = getStaticPreviewUrl(codeGenType, appId.value)
    previewUrl.value = newPreviewUrl
    previewReady.value = true
  }
}

// 滚动到底部
const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

// 下载代码
const downloadCode = async () => {
  if (!appId.value) {
    message.error('应用ID不存在')
    return
  }
  downloading.value = true
  try {
    const API_BASE_URL = request.defaults.baseURL || ''
    const url = `${API_BASE_URL}/app/download/${appId.value}`
    const response = await fetch(url, {
      method: 'GET',
      credentials: 'include',
    })
    if (!response.ok) {
      throw new Error(`下载失败: ${response.status}`)
    }
    // 获取文件名
    const contentDisposition = response.headers.get('Content-Disposition')
    const fileName = contentDisposition?.match(/filename="(.+)"/)?.[1] || `app-${appId.value}.zip`
    // 下载文件
    const blob = await response.blob()
    const downloadUrl = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = downloadUrl
    link.download = fileName
    link.click()
    // 清理
    URL.revokeObjectURL(downloadUrl)
    message.success('代码下载成功')
  } catch (error) {
    console.error('下载失败：', error)
    message.error('下载失败，请重试')
  } finally {
    downloading.value = false
  }
}

// 部署应用
const deployApp = async () => {
  if (!appId.value) {
    message.error('应用ID不存在')
    return
  }

  deploying.value = true
  try {
    const res = await deployAppApi({
      appId: appId.value as unknown as number,
    })

    if (res.data.code === 0 && res.data.data) {
      deployUrl.value = res.data.data
      deployModalVisible.value = true
      message.success('部署成功')
    } else {
      message.error('部署失败：' + res.data.message)
    }
  } catch (error) {
    console.error('部署失败：', error)
    message.error('部署失败，请重试')
  } finally {
    deploying.value = false
  }
}

// 在新窗口打开预览
const openInNewTab = () => {
  if (previewUrl.value) {
    window.open(previewUrl.value, '_blank')
  }
}

// 打开部署的网站
const openDeployedSite = () => {
  if (deployUrl.value) {
    window.open(deployUrl.value, '_blank')
  }
}

// iframe加载完成
const onIframeLoad = () => {
  previewReady.value = true
  const iframe = document.querySelector('.preview-iframe') as HTMLIFrameElement
  if (iframe) {
    visualEditor.init(iframe)
    visualEditor.onIframeLoad()
  }
}

// 编辑应用
const editApp = () => {
  if (appInfo.value?.id) {
    router.push(`/app/edit/${appInfo.value.id}`)
  }
}

// 删除应用
const deleteApp = async () => {
  if (!appInfo.value?.id) return

  try {
    const res = await deleteAppApi({ id: appInfo.value.id })
    if (res.data.code === 0) {
      message.success('删除成功')
      appDetailVisible.value = false
      router.push('/')
    } else {
      message.error('删除失败：' + res.data.message)
    }
  } catch (error) {
    console.error('删除失败：', error)
    message.error('删除失败')
  }
}

// 可视化编辑相关函数
const toggleEditMode = () => {
  // 检查 iframe 是否已经加载
  const iframe = document.querySelector('.preview-iframe') as HTMLIFrameElement
  if (!iframe) {
    message.warning('请等待页面加载完成')
    return
  }
  // 确保 visualEditor 已初始化
  if (!previewReady.value) {
    message.warning('请等待页面加载完成')
    return
  }
  const newEditMode = visualEditor.toggleEditMode()
  isEditMode.value = newEditMode
}

const clearSelectedElement = () => {
  selectedElementInfo.value = null
  visualEditor.clearSelection()
}

const getInputPlaceholder = () => {
  if (selectedElementInfo.value) {
    return `正在编辑 ${selectedElementInfo.value.tagName.toLowerCase()} 元素，描述您想要的修改...`
  }
  return '描述要修改的内容'
}

// 页面加载时获取应用信息
const handleIframeMessage = (event: MessageEvent) => {
  visualEditor.handleIframeMessage(event)
}

onMounted(() => {
  fetchAppInfo()
  window.addEventListener('message', handleIframeMessage)
})

onUnmounted(() => {
  window.removeEventListener('message', handleIframeMessage)
})


</script>

<style scoped>
#appChatPage {
  height: 100dvh;
  padding: 98px 18px 18px;
  background: var(--ink);
  display: flex;
  flex-direction: column;
}

.header-bar,
.header-left,
.header-right,
.preview-header,
.preview-actions,
.user-message,
.ai-message,
.loading-indicator {
  display: flex;
  align-items: center;
}

.header-bar {
  min-height: 54px;
  padding: 0 4px 12px;
  justify-content: space-between;
  gap: 16px;
}

.header-left,
.header-right,
.preview-actions {
  gap: 9px;
}

.app-name {
  margin: 0;
  color: var(--paper);
  font-size: 20px;
  letter-spacing: -0.03em;
}

.code-gen-type-tag {
  border-color: rgba(199, 255, 66, 0.3);
  background: rgba(199, 255, 66, 0.08);
  color: var(--acid);
}

.header-right :deep(.ant-btn) {
  border-color: var(--line);
  border-radius: 10px;
  background: #151815;
  color: var(--paper);
}

.main-content {
  min-height: 0;
  flex: 1;
  display: grid;
  grid-template-columns: minmax(320px, 0.72fr) minmax(480px, 1.28fr);
  gap: 10px;
}

.chat-section,
.preview-section {
  min-height: 0;
  border: 1px solid var(--line);
  border-radius: 18px;
  background: #111411;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.messages-container {
  min-height: 0;
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  scroll-behavior: smooth;
}

.message-item {
  margin-bottom: 18px;
}

.user-message,
.ai-message {
  align-items: flex-start;
  gap: 10px;
}

.user-message {
  justify-content: flex-end;
}

.message-content {
  max-width: 82%;
  padding: 12px 15px;
  border-radius: 14px;
  line-height: 1.55;
  overflow-wrap: anywhere;
}

.user-message .message-content {
  border-bottom-right-radius: 4px;
  background: var(--acid);
  color: var(--ink);
}

.ai-message .message-content {
  border: 1px solid var(--line);
  border-bottom-left-radius: 4px;
  background: #191d19;
  color: var(--paper);
}

.loading-indicator {
  gap: 8px;
  color: var(--muted);
}

.load-more-container {
  padding: 4px 0 18px;
  text-align: center;
}

.selected-element-alert {
  margin: 0 14px 10px;
  border-color: rgba(141, 162, 255, 0.35);
  background: rgba(141, 162, 255, 0.08);
}

.element-header {
  margin-bottom: 7px;
}

.element-id,
.element-class {
  margin-left: 6px;
  color: var(--acid);
}

.element-selector-code {
  padding: 2px 5px;
  border-radius: 4px;
  background: #0b0d0c;
  color: var(--cobalt);
}

.input-container {
  padding: 12px;
  border-top: 1px solid var(--line);
  background: #0e110e;
}

.input-wrapper {
  position: relative;
}

.input-wrapper :deep(textarea.ant-input) {
  min-height: 96px;
  padding: 14px 52px 14px 14px;
  border-radius: 13px;
  resize: none;
}

.input-actions {
  position: absolute;
  right: 8px;
  bottom: 8px;
}

.input-actions :deep(.ant-btn) {
  width: 38px;
  height: 38px;
  border-radius: 10px;
}

.preview-header {
  min-height: 58px;
  padding: 0 16px;
  border-bottom: 1px solid var(--line);
  justify-content: space-between;
}

.preview-header h3 {
  margin: 0;
  font-size: 15px;
}

.preview-content {
  position: relative;
  min-height: 0;
  flex: 1;
  margin: 10px;
  border-radius: 11px;
  background: #090b0a;
  overflow: hidden;
}

.preview-placeholder,
.preview-loading {
  height: 100%;
  color: var(--muted);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.placeholder-icon {
  margin-bottom: 16px;
  color: var(--acid);
  font-size: 44px;
}

.preview-iframe {
  width: 100%;
  height: 100%;
  border: 0;
  background: white;
}

.edit-mode-active {
  color: var(--acid) !important;
}

@media (max-width: 1050px) {
  #appChatPage { height: auto; min-height: 100dvh; }
  .main-content { grid-template-columns: 1fr; }
  .chat-section,
  .preview-section { min-height: 620px; }
}

@media (max-width: 680px) {
  #appChatPage { padding: 82px 10px 10px; }
  .header-bar { align-items: flex-start; flex-direction: column; }
  .header-right { width: 100%; overflow-x: auto; }
  .chat-section,
  .preview-section { min-height: 560px; }
  .message-content { max-width: 88%; }
}

/* Three-zone light studio matching the approved design reference. */
#appChatPage {
  height: 100dvh;
  padding: 0;
  background: #f4f5f1;
  color: #11130f;
}

.studio-header {
  min-height: 76px;
  padding: 0 20px;
  border-bottom: 1px solid #e1e4dc;
  background: rgba(255, 255, 255, 0.96);
  display: grid;
  grid-template-columns: minmax(300px, 1fr) auto minmax(300px, 1fr);
  align-items: center;
  gap: 18px;
}

.studio-identity,
.studio-brand,
.studio-actions,
.project-name,
.workspace-switcher,
.preview-toolbar,
.browser-address,
.viewport-controls {
  display: flex;
  align-items: center;
}

.studio-identity {
  min-width: 0;
  gap: 16px;
}

.studio-brand {
  flex: 0 0 auto;
  gap: 10px;
  color: #11130f;
  font-size: 20px;
  text-decoration: none;
}

.studio-mark {
  position: relative;
  width: 30px;
  height: 26px;
}

.studio-mark i {
  position: absolute;
  width: 28px;
  height: 9px;
  border-radius: 2px;
  background: #11130f;
  transform: skewX(-30deg);
}

.studio-mark i:last-child {
  top: 15px;
  transform: skewX(-30deg) rotate(180deg);
}

.header-divider {
  width: 1px;
  height: 28px;
  background: #dfe2da;
}

.project-name {
  min-width: 0;
  padding: 8px 0;
  border: 0;
  background: transparent;
  color: #20231f;
  cursor: pointer;
  font-weight: 700;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.project-name span,
.project-name b {
  margin-right: 8px;
  color: #747a72;
  font-weight: 500;
}

.workspace-switcher {
  padding: 3px;
  border: 1px solid #dfe2da;
  border-radius: 13px;
  background: #f7f8f4;
}

.workspace-switcher button {
  min-width: 76px;
  padding: 9px 18px;
  border: 0;
  border-radius: 10px;
  background: transparent;
  color: #676d65;
  font-weight: 700;
}

.workspace-switcher button.active {
  border: 1px solid #b0dd2c;
  background: #f7ffdc;
  color: #11130f;
}

.workspace-switcher button:disabled {
  cursor: not-allowed;
  opacity: 0.48;
}

.studio-actions {
  justify-content: flex-end;
  gap: 9px;
}

.mode-label {
  padding: 7px 10px;
  color: #646a62;
  font-size: 13px;
  font-weight: 700;
}

.studio-actions :deep(.ant-btn) {
  height: 42px;
  padding: 0 17px;
  border-color: #dfe2da;
  border-radius: 11px;
  background: #fff;
  color: #11130f;
  box-shadow: none;
  font-weight: 700;
}

.studio-actions :deep(.deploy-button) {
  border-color: #11130f !important;
  background: #11130f !important;
  color: #fff !important;
}

.studio-main {
  min-height: 0;
  flex: 1;
  padding: 12px;
  display: grid;
  grid-template-columns: minmax(290px, 330px) minmax(520px, 1fr) minmax(220px, 250px);
  gap: 12px;
}

.chat-section,
.preview-section,
.inspector-section {
  min-height: 0;
  border: 1px solid #dfe2da;
  border-radius: 16px;
  background: #fff;
  box-shadow: 0 12px 36px rgba(41, 48, 32, 0.035);
  overflow: hidden;
}

.chat-section,
.preview-section,
.inspector-section {
  display: flex;
  flex-direction: column;
}

.panel-heading {
  min-height: 76px;
  padding: 16px 18px;
  border-bottom: 1px solid #eceee8;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.panel-heading p,
.panel-heading span {
  display: block;
  margin: 0;
}

.panel-heading p {
  font-size: 15px;
  font-weight: 800;
}

.panel-heading span {
  margin-top: 4px;
  color: #7b8178;
  font-size: 12px;
}

.panel-heading button {
  width: 34px;
  height: 34px;
  border: 0;
  border-radius: 9px;
  background: #f2f3ef;
  color: #555b53;
  cursor: pointer;
}

.messages-container {
  padding: 18px 16px;
  background: #fbfcf9;
}

.message-item {
  margin-bottom: 20px;
}

.user-message,
.ai-message {
  justify-content: flex-start;
  gap: 10px;
}

.message-avatar {
  flex: 0 0 auto;
}

.ai-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: #11130f;
  color: #fff;
  display: grid;
  place-items: center;
  font-weight: 800;
}

.message-content {
  max-width: calc(100% - 42px);
  padding: 12px 14px;
  border-radius: 12px;
  color: #252824;
  font-size: 13px;
}

.user-message .message-content {
  border: 1px solid #e2e5dd;
  border-bottom-left-radius: 4px;
  border-bottom-right-radius: 12px;
  background: #f1f2ee;
  color: #252824;
}

.ai-message .message-content {
  border: 1px solid #e2e5dd;
  border-bottom-left-radius: 4px;
  background: #fff;
  color: #252824;
}

.loading-indicator {
  color: #727870;
}

.empty-conversation {
  min-height: 100%;
  padding: 30px 20px;
  display: grid;
  place-content: center;
  justify-items: center;
  text-align: center;
}

.empty-conversation > span {
  width: 42px;
  height: 42px;
  border-radius: 50%;
  background: #11130f;
  color: #fff;
  display: grid;
  place-items: center;
  font-weight: 800;
}

.empty-conversation h2 {
  margin: 18px 0 0;
  font-size: 20px;
}

.empty-conversation p {
  margin: 8px 0 0;
  color: #747a72;
  font-size: 13px;
}

.input-container {
  padding: 14px;
  border-top-color: #eceee8;
  background: #fff;
}

.input-wrapper :deep(textarea.ant-input) {
  min-height: 86px;
  padding: 13px 50px 13px 13px;
  border-color: #dfe2da !important;
  border-radius: 12px;
  background: #fff !important;
  color: #11130f !important;
  box-shadow: none !important;
}

.input-wrapper :deep(textarea.ant-input::placeholder) {
  color: #8b9088 !important;
}

.input-actions :deep(.ant-btn) {
  border-radius: 999px;
}

.preview-toolbar {
  min-height: 58px;
  padding: 9px 12px;
  border-bottom: 1px solid #eceee8;
  gap: 10px;
}

.browser-address {
  min-width: 0;
  flex: 1;
  height: 38px;
  padding: 0 13px;
  border-radius: 10px;
  background: #f1f2ee;
  color: #777d74;
  font-size: 12px;
  overflow: hidden;
}

.browser-address > span:last-child {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.browser-dots {
  margin-right: 12px;
  display: flex;
  gap: 5px;
}

.browser-dots i {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #cfd3ca;
}

.browser-dots i:first-child {
  background: #c8f43d;
}

.viewport-controls {
  padding: 3px;
  border: 1px solid #e1e4dc;
  border-radius: 10px;
  gap: 2px;
}

.viewport-controls button,
.toolbar-icon {
  width: 32px;
  height: 30px;
  border: 0;
  border-radius: 7px;
  background: transparent;
  color: #6f756d;
  cursor: pointer;
}

.viewport-controls button.active {
  outline: 1px solid #aed82e;
  background: #f5ffda;
  color: #11130f;
}

.zoom-label {
  padding: 8px 10px;
  border: 1px solid #e1e4dc;
  border-radius: 10px;
  color: #555b53;
  font-size: 12px;
  font-weight: 700;
}

.preview-content {
  margin: 0;
  border-radius: 0;
  background: #eceee8;
  display: flex;
  align-items: stretch;
  justify-content: center;
  overflow: auto;
}

.preview-stage {
  width: 100%;
  height: 100%;
  margin: 0 auto;
  background: #fff;
  box-shadow: 0 14px 48px rgba(33, 39, 27, 0.12);
  transition: width 220ms ease;
}

.preview-stage.viewport-tablet {
  width: min(768px, 100%);
}

.preview-stage.viewport-mobile {
  width: min(390px, 100%);
}

.preview-placeholder,
.preview-loading {
  width: 100%;
  color: #757b73;
}

.placeholder-icon {
  color: #a9db1e;
}

.inspector-section {
  background: #fff;
}

.inspector-block {
  padding: 20px;
}

.inspector-block + .inspector-block {
  border-top: 1px solid #eceee8;
}

.inspector-block h2 {
  margin: 0 0 16px;
  color: #11130f;
  font-size: 16px;
}

.page-block {
  min-height: 190px;
}

.page-row {
  width: 100%;
  padding: 12px 13px;
  border: 1px solid transparent;
  border-radius: 10px;
  background: transparent;
  color: #4f554d;
  display: flex;
  align-items: center;
  gap: 10px;
  text-align: left;
}

.page-row.active {
  border-color: #b4df37;
  background: #f7ffdf;
  color: #11130f;
}

.selection-block {
  flex: 1;
}

.selection-block > p {
  margin: 0 0 18px;
  color: #747a72;
  font-size: 13px;
  line-height: 1.65;
}

.selected-summary {
  margin-bottom: 14px;
  padding: 13px;
  border-radius: 10px;
  background: #f3f4f0;
  display: grid;
  gap: 7px;
}

.selected-summary span,
.selected-summary code {
  color: #70766e;
  font-size: 12px;
  overflow-wrap: anywhere;
}

.clear-selection {
  margin-bottom: 12px;
  padding: 0;
  border: 0;
  background: transparent;
  color: #62685f;
  cursor: pointer;
}

.edit-button {
  width: 100%;
  min-height: 42px;
  border: 1px solid #b4df37;
  border-radius: 10px;
  background: #fff;
  color: #11130f;
  cursor: pointer;
  font-weight: 700;
}

.edit-button.active {
  background: #c8f43d;
}

@media (max-width: 1180px) {
  .studio-header {
    grid-template-columns: minmax(280px, 1fr) auto;
  }

  .workspace-switcher {
    display: none;
  }

  .studio-main {
    grid-template-columns: minmax(280px, 320px) minmax(480px, 1fr);
  }

  .inspector-section {
    display: none;
  }
}

@media (max-width: 820px) {
  #appChatPage {
    height: auto;
    min-height: 100dvh;
  }

  .studio-header {
    min-height: auto;
    padding: 14px;
    grid-template-columns: 1fr;
  }

  .studio-actions {
    justify-content: flex-start;
  }

  .mode-label {
    display: none;
  }

  .studio-main {
    grid-template-columns: 1fr;
  }

  .chat-section,
  .preview-section {
    min-height: 620px;
  }
}

@media (max-width: 560px) {
  .studio-brand strong,
  .header-divider,
  .project-name span,
  .project-name b {
    display: none;
  }

  .studio-actions :deep(.ant-btn) {
    flex: 1;
  }

  .preview-toolbar {
    flex-wrap: wrap;
  }

  .browser-address {
    flex-basis: 100%;
  }

  .zoom-label {
    margin-left: auto;
  }
}
</style>
