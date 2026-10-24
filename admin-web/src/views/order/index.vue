<template>
  <el-card class="page-card">
    <div class="table-toolbar">
      <el-select
        v-model="status"
        placeholder="工单状态"
        clearable
        style="width: 160px"
        @change="onFilter"
      >
        <el-option v-for="(label, key) in statusLabels" :key="key" :label="label" :value="key" />
      </el-select>
      <el-input
        v-model="keyword"
        placeholder="订单号搜索"
        clearable
        style="width: 220px"
        @keyup.enter="onFilter"
      />
      <el-button type="primary" @click="onFilter">查询</el-button>
    </div>

    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="orderNo" label="订单号" width="200" />
      <el-table-column prop="deviceCategoryName" label="设备类型" width="120" />
      <el-table-column prop="faultDesc" label="故障描述" min-width="180" show-overflow-tooltip />
      <el-table-column prop="addressText" label="地址" min-width="160" show-overflow-tooltip />
      <el-table-column prop="engineerName" label="工程师" width="100" />
      <el-table-column prop="urgencyLabel" label="紧急度" width="80" />
      <el-table-column label="状态" width="110">
        <template #default="{ row }">
          <el-tag :type="statusType(row.status)">{{ row.statusLabel }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createdAt" label="创建时间" width="170" />
      <el-table-column label="操作" width="200" fixed="right">
        <template #default="{ row }">
          <el-button
            v-if="row.status === 'PENDING'"
            type="primary"
            size="small"
            @click="onAssign(row, 'assign')"
          >
            指派
          </el-button>
          <el-button
            v-if="row.status === 'ACCEPTED'"
            type="warning"
            size="small"
            @click="onAssign(row, 'reassign')"
          >
            改派
          </el-button>
          <el-button
            v-if="['PENDING', 'ACCEPTED', 'REPAIRING'].includes(row.status)"
            type="danger"
            size="small"
            @click="onClose(row)"
          >
            关闭
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination
      class="pager"
      layout="prev, pager, next, total"
      :total="total"
      :page-size="size"
      :current-page="page"
      @current-change="onPage"
    />

    <!-- 指派/改派：TODO(3.3.1) 改为“附近在线工程师”选择器（地图 + 距离排序） -->
    <el-dialog v-model="assignVisible" :title="assignMode === 'assign' ? '指派工程师' : '改派工程师'" width="380px">
      <el-input v-model.number="assignEngineerId" placeholder="输入工程师用户 ID" type="number" />
      <template #footer>
        <el-button @click="assignVisible = false">取消</el-button>
        <el-button type="primary" @click="doAssign">确定</el-button>
      </template>
    </el-dialog>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { assignOrder, closeOrder, listOrders, reassignOrder, type OrderRow } from '../../api/modules'

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

const rows = ref<OrderRow[]>([])
const total = ref(0)
const page = ref(1)
const size = 10
const status = ref<string>()
const keyword = ref('')
const loading = ref(false)

const assignVisible = ref(false)
const assignMode = ref<'assign' | 'reassign'>('assign')
const assignEngineerId = ref<number>()
const assignOrderRow = ref<OrderRow>()

const load = async () => {
  loading.value = true
  try {
    const data = await listOrders({
      status: status.value,
      keyword: keyword.value || undefined,
      page: page.value,
      size
    })
    rows.value = data.list
    total.value = data.total
  } finally {
    loading.value = false
  }
}

const onFilter = () => {
  page.value = 1
  load()
}

const onPage = (p: number) => {
  page.value = p
  load()
}

const onAssign = (row: OrderRow, mode: 'assign' | 'reassign') => {
  assignOrderRow.value = row
  assignMode.value = mode
  assignEngineerId.value = undefined
  assignVisible.value = true
}

const doAssign = async () => {
  if (!assignEngineerId.value || !assignOrderRow.value) {
    ElMessage.warning('请输入工程师 ID')
    return
  }
  const row = assignOrderRow.value
  if (assignMode.value === 'assign') {
    await assignOrder(row.id, assignEngineerId.value)
  } else {
    await reassignOrder(row.id, assignEngineerId.value)
  }
  ElMessage.success('操作成功')
  assignVisible.value = false
  load()
}

const onClose = async (row: OrderRow) => {
  const { value } = await ElMessageBox.prompt('请填写关闭原因', `关闭工单 ${row.orderNo}`, {
    inputValidator: (v) => (v && v.trim() ? true : '原因不能为空')
  })
  await closeOrder(row.id, value.trim())
  ElMessage.success('已关闭')
  load()
}

const statusType = (status: string) => {
  switch (status) {
    case 'PENDING':
      return 'warning'
    case 'COMPLETED':
    case 'REVIEWED':
      return 'success'
    case 'CANCELLED':
    case 'CLOSED_UNRESOLVED':
      return 'info'
    case 'REPAIRING':
    case 'PENDING_CONFIRM':
      return 'primary'
    default:
      return 'primary'
  }
}

onMounted(load)
</script>

<style scoped>
.pager {
  margin-top: 16px;
  justify-content: flex-end;
}
</style>
