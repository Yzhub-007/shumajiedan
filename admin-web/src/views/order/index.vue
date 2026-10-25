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
      <el-table-column prop="orderNo" label="订单号" width="190" />
      <el-table-column prop="deviceCategoryName" label="设备类型" width="110" />
      <el-table-column prop="faultDesc" label="故障描述" min-width="170" show-overflow-tooltip />
      <el-table-column prop="engineerName" label="工程师" width="90" />
      <el-table-column prop="urgencyLabel" label="紧急度" width="80" />
      <el-table-column label="状态" width="105">
        <template #default="{ row }">
          <el-tag :type="statusType(row.status)">{{ row.statusLabel }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createdAt" label="创建时间" width="165" />
      <el-table-column label="操作" width="250" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="openDetail(row)">详情</el-button>
          <el-button
            v-if="row.status === 'PENDING'"
            type="primary"
            size="small"
            @click="openAssign(row, 'assign')"
          >
            指派
          </el-button>
          <el-button
            v-if="row.status === 'ACCEPTED'"
            type="warning"
            size="small"
            @click="openAssign(row, 'reassign')"
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

    <!-- 指派/改派：附近在线工程师选择（计划书 3.3.1） -->
    <el-dialog
      v-model="assignVisible"
      :title="assignMode === 'assign' ? '指派工程师' : '改派工程师'"
      width="640px"
    >
      <el-table
        :data="nearby"
        v-loading="nearbyLoading"
        highlight-current-row
        @current-change="(row: NearbyEngineer | null) => (selectedEngineer = row ?? undefined)"
        max-height="320"
        empty-text="附近暂无在线工程师，可直接输入工程师 ID"
      >
        <el-table-column prop="realName" label="姓名" width="100" />
        <el-table-column label="距离" width="100">
          <template #default="{ row }">{{ (row.distanceM / 1000).toFixed(1) }} km</template>
        </el-table-column>
        <el-table-column prop="ratingAvg" label="评分" width="80" />
        <el-table-column prop="orderCount" label="完成单数" width="90" />
        <el-table-column label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.onlineStatus ? 'success' : 'info'" size="small">
              {{ row.onlineStatus ? '在线' : '离线' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
      <div class="manual-id">
        <el-input
          v-model.number="manualEngineerId"
          placeholder="或直接输入工程师用户 ID"
          type="number"
          style="width: 220px"
        />
      </div>
      <template #footer>
        <el-button @click="assignVisible = false">取消</el-button>
        <el-button type="primary" @click="doAssign">确定</el-button>
      </template>
    </el-dialog>

    <!-- 工单详情只读抽屉（计划书 2.3.4） -->
    <el-drawer v-model="detailVisible" :title="`工单详情 ${detailRow?.orderNo ?? ''}`" size="520px">
      <div v-if="detail" v-loading="detailLoading">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="设备类型">{{ detail.order.deviceCategoryName }}</el-descriptions-item>
          <el-descriptions-item label="紧急度">{{ detail.order.urgencyLabel }}</el-descriptions-item>
          <el-descriptions-item label="品牌型号">
            {{ detail.order.deviceBrand }} {{ detail.order.deviceModel }}
          </el-descriptions-item>
          <el-descriptions-item label="状态">{{ detail.order.statusLabel }}</el-descriptions-item>
          <el-descriptions-item label="地址" :span="2">{{ detail.order.addressText }}</el-descriptions-item>
          <el-descriptions-item label="故障描述" :span="2">{{ detail.order.faultDesc }}</el-descriptions-item>
          <el-descriptions-item v-if="detail.engineer" label="工程师" :span="2">
            {{ detail.engineer.realName }}（评分 {{ detail.engineer.ratingAvg }}，
            完成 {{ detail.engineer.orderCount }} 单，{{ detail.engineer.phone }}）
          </el-descriptions-item>
        </el-descriptions>

        <h4>故障照片</h4>
        <div v-if="(detail.order.mediaUrls ?? []).length" class="photos">
          <el-image
            v-for="(url, i) in detail.order.mediaUrls"
            :key="i"
            :src="url"
            :preview-src-list="detail.order.mediaUrls"
            fit="cover"
            class="photo"
          />
        </div>
        <p v-else class="muted">无</p>

        <h4>状态流水</h4>
        <el-timeline>
          <el-timeline-item
            v-for="(log, i) in detail.statusLogs"
            :key="i"
            :timestamp="log.createdAt"
          >
            {{ log.fromStatusLabel ?? '—' }} → {{ log.toStatusLabel }}
            <span v-if="log.remark" class="muted">（{{ log.remark }}）</span>
          </el-timeline-item>
        </el-timeline>

        <h4>报价记录</h4>
        <el-table v-if="detail.quotes.length" :data="detail.quotes" size="small" border>
          <el-table-column prop="laborFee" label="工时费" width="90" />
          <el-table-column prop="partsFee" label="配件费" width="90" />
          <el-table-column prop="total" label="合计" width="90" />
          <el-table-column prop="status" label="状态" width="90" />
          <el-table-column prop="createdAt" label="时间" />
        </el-table>
        <p v-else class="muted">无报价</p>

        <template v-if="detail.report">
          <h4>维修报告</h4>
          <p>诊断：{{ detail.report.diagnosis }}</p>
          <p>方案：{{ detail.report.solution }}</p>
          <div v-if="detail.report.afterPhotos.length" class="photos">
            <el-image
              v-for="(url, i) in detail.report.afterPhotos"
              :key="i"
              :src="url"
              :preview-src-list="detail.report.afterPhotos"
              fit="cover"
              class="photo"
            />
          </div>
        </template>
      </div>
    </el-drawer>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  assignOrder,
  closeOrder,
  getOrderDetail,
  listNearbyEngineers,
  listOrders,
  reassignOrder,
  type NearbyEngineer,
  type OrderDetail,
  type OrderRow
} from '../../api/modules'

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
const assignOrderRow = ref<OrderRow>()
const nearby = ref<NearbyEngineer[]>([])
const nearbyLoading = ref(false)
const selectedEngineer = ref<NearbyEngineer>()
const manualEngineerId = ref<number>()

const detailVisible = ref(false)
const detailLoading = ref(false)
const detailRow = ref<OrderRow>()
const detail = ref<OrderDetail>()

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

const openAssign = async (row: OrderRow, mode: 'assign' | 'reassign') => {
  assignOrderRow.value = row
  assignMode.value = mode
  selectedEngineer.value = undefined
  manualEngineerId.value = undefined
  assignVisible.value = true
  nearbyLoading.value = true
  try {
    nearby.value = await listNearbyEngineers(row.id)
  } catch {
    nearby.value = []
  } finally {
    nearbyLoading.value = false
  }
}

const doAssign = async () => {
  const row = assignOrderRow.value
  if (!row) return
  const engineerId = selectedEngineer.value?.userId ?? manualEngineerId.value
  if (!engineerId) {
    ElMessage.warning('请选择或输入工程师')
    return
  }
  if (assignMode.value === 'assign') {
    await assignOrder(row.id, engineerId)
  } else {
    await reassignOrder(row.id, engineerId)
  }
  ElMessage.success('操作成功')
  assignVisible.value = false
  load()
}

const openDetail = async (row: OrderRow) => {
  detailRow.value = row
  detail.value = undefined
  detailVisible.value = true
  detailLoading.value = true
  try {
    detail.value = await getOrderDetail(row.id)
  } catch {
    detailVisible.value = false
  } finally {
    detailLoading.value = false
  }
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
.manual-id {
  margin-top: 10px;
}
.photos {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.photo {
  width: 72px;
  height: 72px;
  border-radius: 6px;
}
.muted {
  color: #999;
  font-size: 13px;
}
</style>
