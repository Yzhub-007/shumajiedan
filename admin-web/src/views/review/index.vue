<template>
  <el-card class="page-card">
    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="orderId" label="工单 ID" width="90" />
      <el-table-column prop="fromUserId" label="评价人" width="90" />
      <el-table-column prop="toUserId" label="被评价人" width="90" />
      <el-table-column label="评分" width="140">
        <template #default="{ row }">
          <el-rate :model-value="row.score" disabled />
        </template>
      </el-table-column>
      <el-table-column prop="content" label="评价内容" min-width="240" show-overflow-tooltip />
      <el-table-column prop="createdAt" label="时间" width="170" />
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
import { listReviews } from '../../api/modules'

const rows = ref<Record<string, any>[]>([])
const total = ref(0)
const page = ref(1)
const size = 10
const loading = ref(false)

const load = async () => {
  loading.value = true
  try {
    const data = await listReviews({ page: page.value, size })
    rows.value = data.list
    total.value = data.total
  } finally {
    loading.value = false
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
