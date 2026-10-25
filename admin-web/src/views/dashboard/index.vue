<template>
  <div class="page-card">
    <el-row :gutter="16">
      <el-col :span="6" v-for="card in statCards" :key="card.label">
        <div class="stat-card">
          <div class="stat-icon" :style="{ background: card.color + '1A', color: card.color }">
            <el-icon :size="22"><component :is="card.icon" /></el-icon>
          </div>
          <div class="stat-meta">
            <div class="stat-label">{{ card.label }}</div>
            <div class="stat-value" :style="{ color: card.valueColor ?? '#1d1d1f' }">
              {{ card.value }}
            </div>
          </div>
        </div>
      </el-col>
    </el-row>

    <el-card class="mt">
      <template #header>工单状态分布</template>
      <el-table :data="statusRows">
        <el-table-column prop="label" label="状态" width="180" />
        <el-table-column prop="count" label="数量" width="120" />
        <el-table-column label="占比">
          <template #default="{ row }">
            <el-progress
              :percentage="total ? Math.round((row.count / total) * 100) : 0"
              :stroke-width="10"
            />
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import {
  DocumentAdd,
  UserFilled,
  CircleCheckFilled,
  Clock
} from '@element-plus/icons-vue'
import { statsOverview } from '../../api/modules'

const overview = ref<Record<string, any>>({})
const statusMap = ref<Record<string, number>>({})

const statusLabels: Record<string, string> = {
  PENDING: '待接单',
  ACCEPTED: '已接单',
  ON_THE_WAY: '前往中',
  ARRIVED: '已到达',
  REPAIRING: '维修中',
  PENDING_CONFIRM: '待验收',
  PENDING_PAYMENT: '待支付',
  COMPLETED: '已完成',
  REVIEWED: '已评价',
  CANCELLED: '已取消',
  CLOSED_UNRESOLVED: '无法修复'
}

const statusRows = computed(() =>
  Object.entries(statusMap.value).map(([key, count]) => ({
    label: statusLabels[key] ?? key,
    count
  }))
)
const total = computed(() =>
  Object.values(statusMap.value).reduce((sum, n) => sum + n, 0)
)
const pendingOrders = computed(() => statusMap.value.PENDING ?? 0)

const statCards = computed(() => [
  {
    icon: DocumentAdd,
    label: '今日新增工单',
    value: overview.value.todayOrders ?? '-',
    color: '#1e5aa8'
  },
  {
    icon: UserFilled,
    label: '待审核工程师',
    value: overview.value.pendingVerify ?? '-',
    color: '#ff9500',
    valueColor: '#b26a00'
  },
  {
    icon: CircleCheckFilled,
    label: '认证工程师',
    value: overview.value.approvedEngineers ?? '-',
    color: '#34c759',
    valueColor: '#1d7a34'
  },
  {
    icon: Clock,
    label: '待接单工单',
    value: pendingOrders.value,
    color: '#af52de',
    valueColor: '#7c2ea6'
  }
])

onMounted(async () => {
  const data: any = await statsOverview()
  overview.value = data
  statusMap.value = (data.ordersByStatus as Record<string, number>) ?? {}
})
</script>

<style scoped>
.stat-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 20px;
  background: #ffffff;
  border-radius: 14px;
  box-shadow:
    0 1px 2px rgba(0, 0, 0, 0.04),
    0 4px 16px rgba(0, 0, 0, 0.04);
}
.stat-icon {
  width: 46px;
  height: 46px;
  flex: none;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 13px;
}
.stat-label {
  font-size: 13px;
  color: #6e6e73;
}
.stat-value {
  margin-top: 2px;
  font-size: 26px;
  font-weight: 700;
  letter-spacing: -0.3px;
  line-height: 1.2;
}
.mt {
  margin-top: 16px;
}
</style>
