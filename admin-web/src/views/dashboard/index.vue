<template>
  <div class="page-card">
    <el-row :gutter="16">
      <el-col :span="6">
        <el-card>
          <template #header>今日新增工单</template>
          <div class="num">{{ overview.todayOrders ?? '-' }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <template #header>待审核工程师</template>
          <div class="num warn">{{ overview.pendingVerify ?? '-' }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <template #header>认证工程师</template>
          <div class="num ok">{{ overview.approvedEngineers ?? '-' }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <template #header>待接单工单</template>
          <div class="num warn">{{ pendingOrders }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card class="mt">
      <template #header>工单状态分布</template>
      <el-table :data="statusRows" border>
        <el-table-column prop="label" label="状态" width="180" />
        <el-table-column prop="count" label="数量" width="120" />
        <el-table-column label="占比">
          <template #default="{ row }">
            <el-progress
              :percentage="total ? Math.round((row.count / total) * 100) : 0"
              :stroke-width="14"
            />
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
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

onMounted(async () => {
  const data: any = await statsOverview()
  overview.value = data
  statusMap.value = (data.ordersByStatus as Record<string, number>) ?? {}
})
</script>

<style scoped>
.num {
  font-size: 32px;
  font-weight: 700;
}
.num.warn {
  color: #e6a23c;
}
.num.ok {
  color: #67c23a;
}
.mt {
  margin-top: 16px;
}
</style>
