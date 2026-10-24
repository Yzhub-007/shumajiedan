<template>
  <el-card class="page-card">
    <div class="table-toolbar">
      <el-select
        v-model="verifyStatus"
        placeholder="审核状态"
        clearable
        style="width: 160px"
        @change="load"
      >
        <el-option label="待审核" value="PENDING" />
        <el-option label="已通过" value="APPROVED" />
        <el-option label="已拒绝" value="REJECTED" />
      </el-select>
      <el-button :icon="Refresh" @click="load" />
    </div>

    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="userId" label="ID" width="70" />
      <el-table-column prop="realName" label="姓名" width="110" />
      <el-table-column prop="idCardNo" label="身份证号" width="210" />
      <el-table-column label="技能标签" min-width="180">
        <template #default="{ row }">
          <el-tag
            v-for="tag in row.skillTags ?? []"
            :key="tag"
            size="small"
            class="tag"
          >
            {{ tag }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="ratingAvg" label="评分" width="80" />
      <el-table-column prop="orderCount" label="完成单数" width="90" />
      <el-table-column label="审核状态" width="100">
        <template #default="{ row }">
          <el-tag :type="statusType(row.verifyStatus)">
            {{ row.verifyStatusLabel }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="资质材料" width="120">
        <template #default="{ row }">
          <el-image
            v-if="row.idCardFrontUrl"
            :src="row.idCardFrontUrl"
            :preview-src-list="[row.idCardFrontUrl, row.idCardBackUrl].filter(Boolean)"
            fit="cover"
            style="width: 48px; height: 32px; border-radius: 4px"
          />
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="180" fixed="right">
        <template #default="{ row }">
          <template v-if="row.verifyStatus !== 'APPROVED'">
            <el-button type="success" size="small" @click="onApprove(row)">通过</el-button>
            <el-button type="danger" size="small" @click="onReject(row)">拒绝</el-button>
          </template>
          <span v-else style="color: #999">已通过</span>
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
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'
import { approveEngineer, listEngineers, rejectEngineer } from '../../api/modules'

const rows = ref<any[]>([])
const total = ref(0)
const page = ref(1)
const size = 10
const verifyStatus = ref<string>()
const loading = ref(false)

const load = async () => {
  loading.value = true
  try {
    const data = await listEngineers({ verifyStatus: verifyStatus.value, page: page.value, size })
    rows.value = data.list
    total.value = data.total
  } finally {
    loading.value = false
  }
}

const onPage = (p: number) => {
  page.value = p
  load()
}

const onApprove = async (row: any) => {
  await ElMessageBox.confirm(`确认通过「${row.realName}」的工程师资质？`, '审核确认')
  await approveEngineer(row.userId)
  ElMessage.success('已通过')
  load()
}

const onReject = async (row: any) => {
  const { value } = await ElMessageBox.prompt('请填写拒绝原因', '审核拒绝', {
    inputValidator: (v) => (v && v.trim() ? true : '原因不能为空')
  })
  await rejectEngineer(row.userId, value.trim())
  ElMessage.success('已拒绝')
  load()
}

const statusType = (status: string) =>
  status === 'APPROVED' ? 'success' : status === 'REJECTED' ? 'danger' : 'warning'

onMounted(load)
</script>

<style scoped>
.tag {
  margin-right: 6px;
}
.pager {
  margin-top: 16px;
  justify-content: flex-end;
}
</style>
