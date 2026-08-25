import { Container, getContainer, switchPort } from '@cloudflare/containers'
import { env } from 'cloudflare:workers'
import { apiPort } from './worker-routing.js'

export class ZerocodeContainer extends Container {
  defaultPort = 8125
  requiredPorts = [8124, 8125, 8127]
  sleepAfter = '24h'
  envVars = {
    MYSQL_URL:
      'jdbc:mysql://127.0.0.1:3306/zerocode_microservice?useUnicode=true&characterEncoding=utf-8&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai',
    MYSQL_USERNAME: 'zerocode',
    MYSQL_PASSWORD: env.MYSQL_PASSWORD,
    REDIS_HOST: '127.0.0.1',
    REDIS_PORT: '6379',
    NACOS_ADDRESS: 'N/A',
    ZEROCODE_USER_SERVICE_URL: 'tri://127.0.0.1:50051',
    ZEROCODE_SCREENSHOT_SERVICE_URL: 'tri://127.0.0.1:50052',
    AI_BASE_URL: 'https://api.deepseek.com',
    AI_MODEL: 'deepseek-v4-flash',
    AI_API_KEY: env.AI_API_KEY,
    COS_HOST: env.COS_HOST,
    COS_SECRET_ID: env.COS_SECRET_ID,
    COS_SECRET_KEY: env.COS_SECRET_KEY,
    COS_REGION: env.COS_REGION,
    COS_BUCKET: env.COS_BUCKET,
    CODE_DEPLOY_HOST: 'https://zerocode-microservice.yray1202.workers.dev/api/deploy',
  }
}

export default {
  async fetch(request) {
    const url = new URL(request.url)
    if (url.pathname.startsWith('/api')) {
      return getContainer(env.ZEROCODE_CONTAINER, 'production').fetch(
        switchPort(request, apiPort(url.pathname)),
      )
    }
    return env.ASSETS.fetch(request)
  },
}
