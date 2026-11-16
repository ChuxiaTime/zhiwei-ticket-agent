<!-- 提交工单页 —— 表单 + AI 分析结果区 -->
<template>
  <el-card>
    <!-- 标题与副标题 -->
    <h2 style="margin: 0">提交工单</h2>
    <p class="page-subtitle">描述故障后，AI 会自动完成分类、检索与建议生成</p>

    <!-- 提交表单 -->
    <el-form :model="form" label-width="100px" style="max-width: 760px; margin-top: 24px" v-loading="loading">
      <el-form-item label="故障类型">
        <el-select v-model="form.faultType" placeholder="若不确定可不选，AI 会自动识别">
          <el-option label="网络" value="network" />
          <el-option label="硬件" value="hardware" />
          <el-option label="软件" value="software" />
          <el-option label="账号" value="account" />
        </el-select>
      </el-form-item>
      <el-form-item label="标题" required>
        <el-input v-model="form.title" placeholder="如：电脑无法连接公司内网" />
      </el-form-item>
      <el-form-item label="故障描述" required>
        <el-input
          v-model="form.description"
          type="textarea"
          :rows="6"
          placeholder="详细描述现象、出现时间、已尝试的操作"
        />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" :loading="loading" @click="onSubmit">提交并让 AI 分析</el-button>
        <el-button @click="form = { title: '', description: '', faultType: '' }">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- AI 分析结果区：仅在提交后显示 -->
    <el-divider v-if="result" />
    <div v-if="result">
      <h3>🤖 AI 分析结果</h3>
      <p>故障类型：<el-tag>{{ formatFaultType(result.fault_type) }}</el-tag></p>

      <el-card class="ai-card" shadow="never" style="margin-top: 12px">
        <div class="ai-card-head">
          <span class="ai-badge">AI</span>
          <span>初步排查建议</span>
        </div>
        <div class="ai-card-body">{{ cleanSuggestion(result.suggestion) }}</div>
      </el-card>

      <h4 style="margin-top: 20px">📎 相似历史工单</h4>
      <el-table v-if="result.similar_tickets.length" :data="result.similar_tickets" border size="small">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="title" label="标题" />
        <el-table-column prop="content" label="内容片段" show-overflow-tooltip />
        <el-table-column label="相似度" width="100">
          <template #default="{ row }">{{ formatScore(row.score) }}</template>
        </el-table-column>
      </el-table>
      <el-empty v-else description="暂无相似历史工单" :image-size="60" />

      <h4 style="margin-top: 20px">📚 知识库参考</h4>
      <el-table v-if="result.similar_knowledge.length" :data="result.similar_knowledge" border size="small">
        <el-table-column prop="title" label="标题" />
        <el-table-column prop="content" label="内容片段" show-overflow-tooltip />
        <el-table-column label="相似度" width="100">
          <template #default="{ row }">{{ formatScore(row.score) }}</template>
        </el-table-column>
      </el-table>
      <el-empty v-else description="暂无知识库命中" :image-size="60" />
    </div>
  </el-card>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import { submitTicket, getTicket } from '@/api/ticket'
import { useRouter } from 'vue-router'
import { cleanSuggestion, formatFaultType, formatScore } from '@/utils/format'

const router = useRouter()

// 表单数据 —— 初始为空，由用户填写
const form = ref({ title: '', description: '', faultType: '' })

const loading = ref(false)

// AI 分析结果 —— 初始为空，结果区隐藏
const result = ref(null)

// 提交：调用后端接口，AI 分析结果回显到当前页面
const onSubmit = async () => {
  if (!form.value.title || !form.value.description) {
    ElMessage.warning('请填写完整')
    return
  }
  loading.value = true
  try {
    const ticket = await submitTicket(form.value)
    const detail = await getTicket(ticket.id)
    result.value = {
      fault_type: detail.faultType,
      suggestion: detail.aiSuggestion,
      similar_tickets: detail.similarTickets ? JSON.parse(detail.similarTickets) : [],
      similar_knowledge: detail.similarKnowledge ? JSON.parse(detail.similarKnowledge) : [],
    }
    ElMessage.success('工单已提交，工单号 #' + ticket.id)
    setTimeout(() => {
      router.push(`/ticket/${ticket.id}`)
    }, 1200)
  } catch (e) {
    // 错误提示由 request 拦截器统一处理
  } finally {
    loading.value = false
  }
}
</script>
