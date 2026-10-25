<template>
  <el-card class="page-card">
    <div class="table-toolbar">
      <el-select v-model="status" placeholder="状态" clearable style="width: 160px" @change="onFilter">
        <el-option label="待审核" value="PENDING" />
        <el-option label="已通过" value="APPROVED" />
        <el-option label="已拒绝" value="REJECTED" />
      </el-select>
      <el-button :icon="Refresh" @click="load" />
    </div>

    <el-table :data="rows" v-loading="loading">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="userId" label="工程师 ID" width="100" />
      <el-table-column prop="amount" label="金额（元）" width="110" />
      <el-table-column label="收款账户" min-width="160">
        <template #default="{ row }">{{ accountText(row.accountInfo) }}</template>
      </el-table-column>
      <el-table-column prop="createdAt" label="申请时间" width="170" />
      <el-table-column label="状态" width="90">
        <template #default="{ row }">
          <el-tag :type="row.status === 'APPROVED' ? 'success' : row.status === 'REJECTED' ? 'danger' : 'warning'">
            {{ statusText(row.status) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="rejectReason" label="拒绝原因" min-width="120" />
      <el-table-column label="操作" width="160" fixed="right">
        <template #default="{ row }">
          <template v-if="row.status === 'PENDING'">
            <el-button type="success" size="small" @click="onApprove(row)">通过</el-button>
            <el-button type="danger" size="small" @click="onReject(row)">拒绝</el-button>
          </template>
          <span v-else style="color: #999">已处理</span>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination
      class="pager"
      layout="prev, pager, next, total"
      :total="total"
      :page-size="size"
      :current-page="page"
      @current-change="(p: number) => { page = p; load() }"
    />
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'
import { approveWithdrawal, listWithdrawals, rejectWithdrawal, type WithdrawalRow } from '../../api/modules'

const rows = ref<WithdrawalRow[]>([])
const total = ref(0)
const page = ref(1)
const size = 10
const status = ref<string>()
const loading = ref(false)

const load = async () => {
  loading.value = true
  try {
    const data = await listWithdrawals({ status: status.value, page: page.value, size })
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

const onApprove = async (row: WithdrawalRow) => {
  await ElMessageBox.confirm(
    `确认通过工程师 ${row.userId} 的提现申请（${row.amount} 元）？通过后需线下完成打款。`,
    '提现审核'
  )
  await approveWithdrawal(row.id)
  ElMessage.success('已通过，请及时打款')
  load()
}

const onReject = async (row: WithdrawalRow) => {
  const { value } = await ElMessageBox.prompt('请填写拒绝原因', '拒绝提现', {
    inputValidator: (v) => (v && v.trim() ? true : '原因不能为空')
  })
  await rejectWithdrawal(row.id, value.trim())
  ElMessage.success('已拒绝，金额退回余额')
  load()
}

const statusText = (s: string) => (s === 'APPROVED' ? '已通过' : s === 'REJECTED' ? '已拒绝' : '待审核')

const accountText = (info: WithdrawalRow['accountInfo']) => {
  if (!info) return '-'
  if (typeof info === 'string') {
    try {
      const parsed = JSON.parse(info)
      return parsed.account ?? info
    } catch {
      return info
    }
  }
  return String((info as Record<string, unknown>).account ?? '-')
}

onMounted(load)
</script>

<style scoped>
.pager {
  margin-top: 16px;
  justify-content: flex-end;
}
</style>
