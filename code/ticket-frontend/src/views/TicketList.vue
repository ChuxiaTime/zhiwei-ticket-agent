<!-- 工单列表页 —— 概览统计 + 搜索条件 + 表格 + 分页 -->
<template>
  <el-card>
    <!-- 头部行：左侧标题，右侧新建按钮 -->
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px">
      <div>
        <h2 style="margin: 0">工单列表</h2>
        <p class="page-subtitle">查看、筛选并处理来自全公司的 IT 运维工单</p>
      </div>
      <el-button @click="$router.push('/ticket/submit')" type="primary">+ 新建工单</el-button>
    </div>

    <!-- 概览统计 -->
    <div class="stats-grid">
      <el-card
        v-for="s in statCards"
        :key="s.key"
        class="stat-card"
        :class="s.class"
        shadow="never"
      >
        <div class="stat-label">{{ s.label }}</div>
        <div class="stat-value">{{ s.value }}</div>
      </el-card>
    </div>

    <!-- 搜索条件：状态 + 提交时间范围 -->
    <el-form :inline="true" :model="query" class="search-bar">
      <el-form-item label="状态">
        <el-select v-model="query.status" placeholder="全部" clearable style="width: 160px">
          <el-option label="待处理" value="PENDING" />
          <el-option label="处理中" value="PROCESSING" />
          <el-option label="已解决" value="RESOLVED" />
          <el-option label="已关闭" value="CLOSED" />
        </el-select>
      </el-form-item>
      <el-form-item label="提交时间">
        <el-date-picker
          v-model="query.dateRange"
          type="daterange"
          value-format="YYYY-MM-DD"
          range-separator="至"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
          style="width: 260px"
        />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="onSearch">查询</el-button>
        <el-button @click="onReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- 工单表格 -->
    <el-table :data="list" v-loading="loading" border>
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="title" label="标题" />
      <el-table-column label="类型" width="100">
        <template #default="{ row }">
          <el-tag v-if="row.faultType" size="small">{{ formatFaultType(row.faultType) }}</el-tag>
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" width="110">
        <template #default="{ row }">
          <el-tag :type="statusTag[row.status]" size="small">{{ statusLabel[row.status] }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="提交时间" width="180">
        <template #default="{ row }">{{ formatTime(row.createTime) }}</template>
      </el-table-column>
      <el-table-column label="操作" width="120">
        <template #default="{ row }">
          <el-button size="small" @click="$router.push(`/ticket/${row.id}`)">详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页：靠右 -->
    <el-pagination
      v-model:current-page="page"
      v-model:page-size="size"
      :page-sizes="[10, 20, 50]"
      layout="total, sizes, prev, pager, next"
      :total="total"
      style="margin-top: 16px; text-align: right"
      @current-change="load"
      @size-change="onSearch"
    />
  </el-card>
</template>

<script setup>
import { computed, reactive, ref, onMounted } from 'vue'
import { listTickets } from '@/api/ticket'
import { listKnowledge } from '@/api/knowledge'
import { formatFaultType, formatTime } from '@/utils/format'

// 搜索表单：status 单选，dateRange 为 [开始日期, 结束日期]（YYYY-MM-DD）
const query = reactive({ status: '', dateRange: [] })

// 工单列表数据，由接口加载
const list = ref([])

// 分页与加载状态
const total = ref(0)
const page = ref(1)
const size = ref(10)
const loading = ref(false)

// 概览统计
const stats = reactive({ total: 0, pending: 0, processing: 0, resolved: 0, knowledge: 0 })

const statCards = computed(() => [
  { key: 'total', label: '全部工单', value: stats.total, class: 'accent-indigo' },
  { key: 'pending', label: '待处理', value: stats.pending, class: 'accent-amber' },
  { key: 'processing', label: '处理中', value: stats.processing, class: 'accent-teal' },
  { key: 'resolved', label: '已解决', value: stats.resolved, class: 'accent-green' },
  { key: 'knowledge', label: '知识库条目', value: stats.knowledge, class: 'accent-slate' },
])

// 状态文案映射
const statusLabel = {
  PENDING: '待处理',
  PROCESSING: '处理中',
  RESOLVED: '已解决',
  CLOSED: '已关闭',
}

// 状态标签颜色映射
const statusTag = {
  PENDING: 'warning',
  PROCESSING: 'primary',
  RESOLVED: 'success',
  CLOSED: 'info',
}

// 查询：回到第 1 页并重新拉取
const onSearch = () => {
  page.value = 1
  load()
}

// 重置：清空搜索条件后触发查询
const onReset = () => {
  query.status = ''
  query.dateRange = []
  onSearch()
}

// 调用列表接口获取当前页数据
const load = async () => {
  loading.value = true
  try {
    const [dateFrom, dateTo] = query.dateRange
    const res = await listTickets({
      page: page.value,
      size: size.value,
      status: query.status,
      dateFrom,
      dateTo,
    })
    list.value = res.list || []
    total.value = res.total || 0
  } finally {
    loading.value = false
  }
}

// 统计卡数据：总量 / 各状态 / 知识库
const loadStats = async () => {
  const [tickets, knowledge] = await Promise.all([
    listTickets({ page: 1, size: 1000 }),
    listKnowledge(),
  ])
  const all = tickets.list || []
  stats.total = tickets.total || all.length
  stats.pending = all.filter((t) => t.status === 'PENDING').length
  stats.processing = all.filter((t) => t.status === 'PROCESSING').length
  stats.resolved = all.filter((t) => t.status === 'RESOLVED').length
  stats.knowledge = (knowledge || []).length
}

onMounted(() => {
  load()
  loadStats()
})
</script>

<style scoped>
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 14px;
  margin-bottom: 18px;
}

.stat-card {
  background: #fff;
  border: 1px solid var(--border-soft);
}

.stat-card :deep(.el-card__body) {
  padding: 16px 18px;
}

.stat-label {
  font-size: 12px;
  color: var(--text-muted);
}

.stat-value {
  margin-top: 6px;
  font-size: 28px;
  font-weight: 700;
  line-height: 1;
  color: var(--brand-primary);
}

.stat-card.accent-amber .stat-value {
  color: #d97706;
}

.stat-card.accent-teal .stat-value {
  color: var(--brand-teal);
}

.stat-card.accent-green .stat-value {
  color: #059669;
}

.stat-card.accent-slate .stat-value {
  color: #475569;
}

.search-bar {
  margin-bottom: 8px;
}
</style>
