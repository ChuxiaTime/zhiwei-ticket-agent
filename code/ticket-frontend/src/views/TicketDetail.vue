<!-- 工单详情页 —— 状态流转 + 基本信息 + AI 建议 + 相似工单/知识库 -->
<template>
  <el-card v-loading="loading">
    <div v-if="ticket">
      <!-- 顶部返回行 -->
      <el-page-header @back="$router.back()" style="margin-bottom: 16px">
        <template #content>
          <span style="font-size: 18px; font-weight: 600">工单 #{{ ticket.id }} - {{ ticket.title }}</span>
        </template>
      </el-page-header>

      <!-- 状态流转 -->
      <el-steps :active="statusStep" finish-status="success" align-center class="status-steps">
        <el-step title="待处理" />
        <el-step title="处理中" />
        <el-step title="已解决" />
        <el-step title="已关闭" />
      </el-steps>

      <!-- 基本信息：两列带边框描述表 -->
      <el-descriptions :column="2" border>
        <el-descriptions-item label="故障类型">
          <el-tag>{{ formatFaultType(ticket.faultType) }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="状态">
          <!-- 管理员 / 运维工程师可更新状态 -->
          <el-select v-if="canHandle" v-model="ticket.status" @change="onSave">
            <el-option label="待处理" value="PENDING" />
            <el-option label="处理中" value="PROCESSING" />
            <el-option label="已解决" value="RESOLVED" />
            <el-option label="已关闭" value="CLOSED" />
          </el-select>
          <!-- 其他角色只读 -->
          <span v-else>{{ statusLabel[ticket.status] }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="提交人ID">{{ ticket.submitterId }}</el-descriptions-item>
        <el-descriptions-item label="提交时间">{{ formatTime(ticket.createTime) }}</el-descriptions-item>
        <el-descriptions-item label="故障描述" :span="2">
          {{ ticket.description }}
        </el-descriptions-item>
        <el-descriptions-item label="处理结果" :span="2">
          <el-input
            v-if="canHandle"
            v-model="resolution"
            type="textarea"
            :rows="3"
            placeholder="请填写处理结果"
            @blur="onSave"
          />
          <!-- 其他角色只读 -->
          <span v-else>{{ resolution }}</span>
        </el-descriptions-item>
      </el-descriptions>

      <el-divider />

      <!-- AI 初步建议 -->
      <el-card class="ai-card" shadow="never">
        <div class="ai-card-head">
          <span class="ai-badge">AI</span>
          <span>初步排查建议</span>
        </div>
        <div class="ai-card-body">{{ cleanSuggestion(ticket.aiSuggestion) }}</div>
      </el-card>

      <!-- 相似历史工单 -->
      <h3 style="margin-top: 24px">📎 相似历史工单</h3>
      <div v-if="similarTickets.length">
        <el-card
          v-for="s in similarTickets"
          :key="'t-' + s.id"
          shadow="never"
          style="margin-bottom: 8px"
        >
          <div style="display: flex; justify-content: space-between; align-items: center">
            <div style="font-weight: 600">#{{ s.id }} {{ s.title }}</div>
            <el-tag size="small" type="warning">相似度 {{ formatScore(s.score) }}</el-tag>
          </div>
          <div style="color: #666; margin-top: 6px; line-height: 1.6">{{ s.content }}</div>
        </el-card>
      </div>
      <el-empty v-else description="暂无相似历史工单（可多提交几条工单试试）" :image-size="80" />

      <!-- 知识库参考 -->
      <h3 style="margin-top: 24px">📚 知识库参考</h3>
      <div v-if="similarKnowledge.length">
        <el-card
          v-for="s in similarKnowledge"
          :key="'k-' + s.id"
          shadow="never"
          style="margin-bottom: 8px"
        >
          <div style="display: flex; justify-content: space-between; align-items: center">
            <div style="font-weight: 600">{{ s.title }}</div>
            <el-tag size="small" type="success">相似度 {{ formatScore(s.score) }}</el-tag>
          </div>
          <div style="color: #666; margin-top: 6px; line-height: 1.6; white-space: pre-line">{{ s.content }}</div>
        </el-card>
      </div>
      <el-empty v-else description="暂无知识库命中" :image-size="80" />
    </div>
  </el-card>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useRoute } from 'vue-router'
import { getTicket, updateTicket } from '@/api/ticket'
import { cleanSuggestion, formatFaultType, formatScore, formatTime } from '@/utils/format'

const route = useRoute()

// 状态中文映射
const statusLabel = { PENDING: '待处理', PROCESSING: '处理中', RESOLVED: '已解决', CLOSED: '已关闭' }

// 当前登录用户：管理员和运维工程师可以处理工单
const user = JSON.parse(localStorage.getItem('ticket_user') || '{}')
const canHandle = computed(() => ['admin', 'engineer'].includes(user?.role))

// 工单详情，由接口加载
const ticket = ref({})

// 处理结果
const resolution = ref('')

const loading = ref(false)

// 状态步骤条位置
const statusStep = computed(() => ({
  PENDING: 0,
  PROCESSING: 1,
  RESOLVED: 2,
  CLOSED: 3,
}[ticket.value.status] ?? 0))

// 解析相似历史工单（后端返回 JSON 字符串）
const similarTickets = computed(() => {
  try {
    return JSON.parse(ticket.value.similarTickets || '[]')
  } catch (e) {
    return []
  }
})

// 解析知识库参考（后端返回 JSON 字符串）
const similarKnowledge = computed(() => {
  try {
    return JSON.parse(ticket.value.similarKnowledge || '[]')
  } catch (e) {
    return []
  }
})

// 保存处理结果
const onSave = async () => {
  try {
    await updateTicket(route.params.id, {
      status: ticket.value.status,
      resolution: resolution.value,
    })
    ElMessage.success('已保存')
  } catch (e) {
    ElMessage.error('保存工单失败')
  }
}

const load = async () => {
  loading.value = true
  try {
    const res = await getTicket(route.params.id)
    ticket.value = res
    // 初始化处理结果为工单当前处理结果
    resolution.value = res.resolution || ''
  } catch (e) {
    ElMessage.error('获取工单详情失败')
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.status-steps {
  margin: 4px 0 24px;
  padding: 18px 8px;
  border: 1px solid #eef2f7;
  border-radius: 14px;
  background: #f8fafc;
}

.status-steps :deep(.el-step__title) {
  font-size: 13px;
}
</style>
