<!-- 主布局：浅色侧边栏 + 顶部面包屑 + 内容区 -->
<template>
  <el-container class="app-shell">
    <el-aside class="sidebar">
      <div class="brand" @click="router.push('/ticket/list')">
        <div class="brand-mark">智</div>
        <div class="brand-copy">
          <strong>智维</strong>
          <span>AI 运维工单中枢</span>
        </div>
      </div>

      <el-menu class="nav-menu" :default-active="activeMenu" router>
        <el-menu-item index="/ticket/list">
          <el-icon><Document /></el-icon>
          <span>工单列表</span>
        </el-menu-item>
        <el-menu-item index="/ticket/submit">
          <el-icon><Edit /></el-icon>
          <span>提交工单</span>
        </el-menu-item>
        <el-menu-item v-if="isAdmin" index="/knowledge">
          <el-icon><Reading /></el-icon>
          <span>知识库管理</span>
        </el-menu-item>
        <el-menu-item index="/chat">
          <el-icon><ChatDotRound /></el-icon>
          <span>AI 助手</span>
        </el-menu-item>
      </el-menu>

      <div class="sidebar-foot">
        <div class="user-card">
          <div class="avatar">{{ (user.realName || user.username || '用').slice(0, 1) }}</div>
          <div class="user-copy">
            <strong>{{ user.realName || user.username || '用户' }}</strong>
            <span>{{ roleLabel }}</span>
          </div>
        </div>
        <el-button text class="logout" @click="onLogout">退出登录</el-button>
      </div>
    </el-aside>

    <el-container class="main-shell">
      <el-header class="topbar">
        <div class="crumb">
          <span>工作台</span>
          <em>/</em>
          <strong>{{ currentTitle }}</strong>
        </div>
        <div class="topbar-right">
          <span class="ai-status"><i></i>AI 服务在线</span>
          <span class="today">{{ today }}</span>
        </div>
      </el-header>

      <el-main class="app-main">
        <div class="page-container">
          <router-view />
        </div>
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessageBox } from 'element-plus'

const route = useRoute()
const router = useRouter()

// 当前登录用户信息（登录时写入 localStorage）
const user = JSON.parse(localStorage.getItem('ticket_user') || '{}')

// 知识库管理仅管理员可见
const isAdmin = user.role === 'admin'

const roleLabel = computed(() => ({
  admin: '管理员',
  engineer: '运维工程师',
  employee: '普通员工',
}[user.role] || '用户'))

const pageTitles = {
  '/ticket/list': '工单列表',
  '/ticket/submit': '提交工单',
  '/knowledge': '知识库管理',
  '/chat': 'AI 助手',
}

const currentTitle = computed(() => {
  if (pageTitles[route.path]) return pageTitles[route.path]
  if (route.path.startsWith('/ticket/')) return '工单详情'
  return '工作台'
})

// 工单详情页仍然高亮“工单列表”菜单
const activeMenu = computed(() => {
  if (route.path.startsWith('/ticket/')) {
    return route.path === '/ticket/submit' ? '/ticket/submit' : '/ticket/list'
  }
  return route.path
})

const today = new Date().toLocaleDateString('zh-CN', {
  year: 'numeric',
  month: 'long',
  day: 'numeric',
  weekday: 'long',
})

// 退出登录 —— 二次确认后跳转登录页
const onLogout = () => {
  ElMessageBox.confirm('确定要退出登录吗？', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning',
  })
    .then(() => {
      localStorage.removeItem('ticket_token')
      localStorage.removeItem('ticket_user')
      router.push('/login')
    })
    .catch(() => {})
}
</script>

<style scoped>
.app-shell {
  min-height: 100vh;
  background: var(--page-bg);
}

.sidebar {
  width: 240px;
  height: 100vh;
  position: sticky;
  top: 0;
  display: flex;
  flex-direction: column;
  padding: 20px 14px 16px;
  background: #fff;
  border-right: 1px solid var(--border-soft);
  flex-shrink: 0;
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 6px 10px 22px;
  cursor: pointer;
}

.brand-mark {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  color: #fff;
  font-weight: 700;
  font-size: 18px;
  background: linear-gradient(135deg, var(--brand-indigo), var(--brand-primary) 55%, var(--brand-teal));
  box-shadow: 0 8px 20px rgba(79, 70, 229, 0.24);
  flex-shrink: 0;
}

.brand-copy {
  display: flex;
  flex-direction: column;
  line-height: 1.15;
}

.brand-copy strong {
  font-size: 18px;
  letter-spacing: 0.08em;
  color: var(--brand-ink);
}

.brand-copy span {
  font-size: 11px;
  color: var(--text-muted);
  letter-spacing: 0.06em;
}

.nav-menu {
  flex: 1;
  border-right: none;
  background: transparent;
}

.nav-menu :deep(.el-menu-item) {
  height: 46px;
  line-height: 46px;
  margin: 4px 0;
  padding: 0 14px !important;
  border-radius: 10px;
  color: #475569;
  font-size: 14px;
}

.nav-menu :deep(.el-menu-item .el-icon) {
  margin-right: 10px;
  font-size: 17px;
}

.nav-menu :deep(.el-menu-item:hover) {
  background: #f1f5f9;
  color: var(--brand-primary);
}

.nav-menu :deep(.el-menu-item.is-active) {
  background: #eef2ff;
  color: var(--brand-primary);
  font-weight: 600;
  box-shadow: inset 3px 0 0 var(--brand-primary);
}

.sidebar-foot {
  margin-top: auto;
  padding-top: 16px;
  border-top: 1px solid #f1f5f9;
}

.user-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 12px;
  background: #f8fafc;
}

.avatar {
  width: 34px;
  height: 34px;
  border-radius: 10px;
  display: grid;
  place-items: center;
  color: #fff;
  font-weight: 600;
  background: linear-gradient(135deg, var(--brand-primary), var(--brand-teal));
  flex-shrink: 0;
}

.user-copy {
  display: flex;
  flex-direction: column;
  min-width: 0;
  line-height: 1.25;
}

.user-copy strong {
  font-size: 13px;
  color: var(--brand-ink);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.user-copy span {
  font-size: 11px;
  color: var(--text-muted);
}

.logout {
  width: 100%;
  margin-top: 8px;
  justify-content: flex-start;
  padding-left: 12px;
  color: var(--text-muted);
}

.main-shell {
  min-width: 0;
}

.topbar {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 32px;
  background: rgba(255, 255, 255, 0.86);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--border-soft);
  position: sticky;
  top: 0;
  z-index: 10;
}

.crumb {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--text-muted);
}

.crumb em {
  font-style: normal;
  color: #cbd5e1;
}

.crumb strong {
  color: var(--brand-ink);
  font-weight: 600;
}

.topbar-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.ai-status {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 5px 10px;
  border-radius: 999px;
  font-size: 12px;
  color: #059669;
  background: #ecfdf5;
}

.ai-status i {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #10b981;
}

.today {
  font-size: 12px;
  color: var(--text-muted);
}

.app-main {
  padding: 24px 32px 40px;
}

.page-container {
  max-width: 1180px;
  margin: 0 auto;
}

@media (max-width: 900px) {
  .sidebar {
    width: 76px;
    padding: 16px 8px;
  }

  .brand {
    justify-content: center;
    padding: 6px 0 18px;
  }

  .brand-copy,
  .nav-menu :deep(.el-menu-item span),
  .user-copy,
  .logout :deep(span) {
    display: none;
  }

  .nav-menu :deep(.el-menu-item) {
    justify-content: center;
    padding: 0 !important;
  }

  .nav-menu :deep(.el-menu-item .el-icon) {
    margin-right: 0;
  }

  .user-card {
    justify-content: center;
    padding: 8px 0;
  }

  .logout {
    justify-content: center;
    padding: 0;
  }

  .topbar {
    padding: 0 16px;
  }

  .today {
    display: none;
  }

  .app-main {
    padding: 18px 12px 28px;
  }
}
</style>
