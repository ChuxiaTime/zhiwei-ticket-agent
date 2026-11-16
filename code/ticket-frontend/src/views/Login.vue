<!-- 登录页：左侧品牌介绍 + 右侧登录面板 -->
<template>
  <div class="login-page">
    <section class="login-brand">
      <div class="brand-mark">智</div>
      <p class="brand-eyebrow">AI-NATIVE IT SERVICE DESK</p>
      <h1>智维<span>·</span></h1>
      <p class="brand-title">企业 IT 智能工单中枢</p>
      <p class="brand-desc">
        从一句话故障描述开始，自动完成分类、相似工单检索与知识库召回，
        把 AI 建议送到工程师手上。
      </p>

      <div class="flow">
        <div class="flow-item">
          <span>01</span>
          <div><strong>描述故障</strong><small>员工提交工单</small></div>
        </div>
        <div class="flow-item">
          <span>02</span>
          <div><strong>AI 分析</strong><small>分类 + 向量检索</small></div>
        </div>
        <div class="flow-item">
          <span>03</span>
          <div><strong>建议回填</strong><small>排查步骤与相似案例</small></div>
        </div>
        <div class="flow-item">
          <span>04</span>
          <div><strong>工程师处理</strong><small>状态流转与知识沉淀</small></div>
        </div>
      </div>

      <div class="tag-row">
        <span>智能分类</span>
        <span>相似工单</span>
        <span>知识库召回</span>
        <span>工具调用</span>
      </div>
    </section>

    <section class="login-panel">
      <el-card class="login-card" shadow="never">
        <div class="login-head">
          <p class="login-eyebrow">WELCOME BACK</p>
          <h2>登录智维</h2>
          <p>使用你的运维账号进入工作台</p>
        </div>

        <el-form :model="form" label-position="top" class="login-form" @submit.prevent>
          <el-form-item label="账号">
            <el-input v-model="form.username" size="large" placeholder="请输入账号">
              <template #prefix><el-icon><User /></el-icon></template>
            </el-input>
          </el-form-item>
          <el-form-item label="密码">
            <el-input
              v-model="form.password"
              type="password"
              show-password
              size="large"
              placeholder="请输入密码"
            >
              <template #prefix><el-icon><Lock /></el-icon></template>
            </el-input>
          </el-form-item>
          <el-button type="primary" size="large" class="login-btn" :loading="loading" @click="onLogin">
            登录工作台
          </el-button>
        </el-form>

        <div class="test-accounts">
          <div class="test-title">测试账号</div>
          <div class="test-row"><span>员工</span><code>employee / 123456</code></div>
          <div class="test-row"><span>管理员</span><code>admin / 123456</code></div>
          <div class="test-row"><span>工程师</span><code>engineer / 123456</code></div>
        </div>

        <p class="login-foot">智维 · 企业 IT 智能工单平台</p>
      </el-card>
    </section>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import { login } from '@/api/user'
import { useRouter } from 'vue-router'

const router = useRouter()

// 登录表单默认值（方便本地调试）
const form = ref({ username: 'employee', password: '123456' })

const loading = ref(false)

// 登录：调用后端接口，成功后保存令牌并跳转
const onLogin = async () => {
  if (!form.value.username || !form.value.password) {
    ElMessage.warning('请输入账号密码')
    return
  }
  loading.value = true
  try {
    const data = await login(form.value)
    localStorage.setItem('ticket_token', data.token)
    localStorage.setItem('ticket_user', JSON.stringify(data))
    ElMessage.success('登录成功')
    router.push('/ticket/list')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 1.15fr 0.85fr;
  background: #f8fafc;
}

.login-brand {
  position: relative;
  overflow: hidden;
  padding: 72px 8vw;
  color: #fff;
  display: flex;
  flex-direction: column;
  justify-content: center;
  background:
    radial-gradient(circle at 15% 15%, rgba(20, 184, 166, 0.35), transparent 35%),
    radial-gradient(circle at 80% 20%, rgba(99, 102, 241, 0.45), transparent 40%),
    linear-gradient(145deg, #0f172a 0%, #1e1b4b 55%, #312e81 100%);
}

.login-brand::before,
.login-brand::after {
  content: '';
  position: absolute;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 50%;
}

.login-brand::before {
  width: 320px;
  height: 320px;
  top: -120px;
  right: 10%;
}

.login-brand::after {
  width: 520px;
  height: 520px;
  right: -180px;
  bottom: -220px;
}

.brand-mark {
  width: 56px;
  height: 56px;
  border-radius: 16px;
  display: grid;
  place-items: center;
  font-size: 24px;
  font-weight: 700;
  background: linear-gradient(135deg, var(--brand-primary), var(--brand-teal));
  box-shadow: 0 16px 40px rgba(20, 184, 166, 0.25);
}

.brand-eyebrow {
  margin: 28px 0 10px;
  font-size: 11px;
  letter-spacing: 0.28em;
  color: #94a3b8;
}

.login-brand h1 {
  margin: 0;
  font-size: 72px;
  line-height: 1;
  letter-spacing: 0.06em;
}

.login-brand h1 span {
  color: var(--brand-teal);
}

.brand-title {
  margin: 14px 0 0;
  font-size: 24px;
  font-weight: 600;
  letter-spacing: 0.04em;
}

.brand-desc {
  margin: 18px 0 0;
  max-width: 520px;
  color: #cbd5e1;
  line-height: 1.9;
  font-size: 14px;
}

.flow {
  margin-top: 40px;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px 28px;
  max-width: 560px;
}

.flow-item {
  display: flex;
  gap: 12px;
  align-items: flex-start;
}

.flow-item span {
  margin-top: 3px;
  font-size: 12px;
  color: var(--brand-teal);
  letter-spacing: 0.1em;
}

.flow-item strong {
  display: block;
  font-size: 14px;
}

.flow-item small {
  display: block;
  margin-top: 4px;
  color: #94a3b8;
  font-size: 12px;
}

.tag-row {
  margin-top: 36px;
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.tag-row span {
  padding: 6px 12px;
  border: 1px solid rgba(148, 163, 184, 0.35);
  border-radius: 999px;
  color: #cbd5e1;
  font-size: 12px;
  background: rgba(255, 255, 255, 0.04);
}

.login-panel {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 48px 6vw;
  background: linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%);
}

.login-card {
  width: 100%;
  max-width: 420px;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  box-shadow: 0 24px 60px rgba(15, 23, 42, 0.08);
}

.login-card :deep(.el-card__body) {
  padding: 40px 36px 30px;
}

.login-eyebrow {
  margin: 0;
  font-size: 11px;
  letter-spacing: 0.24em;
  color: var(--brand-primary);
  font-weight: 600;
}

.login-head h2 {
  margin: 8px 0 6px;
  font-size: 28px;
  color: var(--brand-ink);
}

.login-head p {
  margin: 0;
  color: var(--text-muted);
  font-size: 13px;
}

.login-form {
  margin-top: 28px;
}

.login-form :deep(.el-form-item__label) {
  color: #475569;
  font-weight: 500;
}

.login-btn {
  width: 100%;
  height: 46px;
  margin-top: 6px;
  border: none;
  border-radius: 12px;
  font-weight: 600;
  background: linear-gradient(135deg, var(--brand-primary), #6366f1);
}

.test-accounts {
  margin-top: 22px;
  padding: 14px 16px;
  border: 1px solid #eef2f7;
  border-radius: 12px;
  background: #f8fafc;
}

.test-title {
  margin-bottom: 8px;
  font-size: 12px;
  color: var(--text-muted);
}

.test-row {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 12px;
  line-height: 1.9;
  color: #64748b;
}

.test-row code {
  color: #334155;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
}

.login-foot {
  margin: 20px 0 0;
  text-align: center;
  font-size: 11px;
  letter-spacing: 0.08em;
  color: #94a3b8;
}

@media (max-width: 980px) {
  .login-page {
    grid-template-columns: 1fr;
  }

  .login-brand {
    display: none;
  }

  .login-panel {
    min-height: 100vh;
    padding: 32px 18px;
  }
}
</style>
