<template>
  <el-card class="page-card">
    <div class="table-toolbar">
      <el-select v-model="role" placeholder="角色" clearable style="width: 160px" @change="onFilter">
        <el-option label="客户" value="CUSTOMER" />
        <el-option label="工程师" value="ENGINEER" />
      </el-select>
      <el-button :icon="Refresh" @click="load" />
    </div>

    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="phone" label="手机号（脱敏）" width="150" />
      <el-table-column prop="nickname" label="昵称" min-width="120" />
      <el-table-column label="角色" width="100">
        <template #default="{ row }">
          <el-tag :type="row.role === 'ENGINEER' ? 'warning' : 'primary'" effect="plain">
            {{ row.role === 'ENGINEER' ? '工程师' : '客户' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="状态" width="90">
        <template #default="{ row }">
          <el-tag :type="row.status === 'ACTIVE' ? 'success' : 'danger'">
            {{ row.status === 'ACTIVE' ? '正常' : '已禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createdAt" label="注册时间" width="170" />
      <el-table-column label="操作" width="110" fixed="right">
        <template #default="{ row }">
          <el-button
            v-if="row.status === 'ACTIVE'"
            type="danger"
            size="small"
            @click="onToggle(row, false)"
          >
            禁用
          </el-button>
          <el-button v-else type="success" size="small" @click="onToggle(row, true)">启用</el-button>
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
import { disableUser, enableUser, listUsers, type UserRow } from '../../api/modules'

const rows = ref<UserRow[]>([])
const total = ref(0)
const page = ref(1)
const size = 10
const role = ref<string>()
const loading = ref(false)

const load = async () => {
  loading.value = true
  try {
    const data = await listUsers({ role: role.value, page: page.value, size })
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

const onToggle = async (row: UserRow, enable: boolean) => {
  const action = enable ? '启用' : '禁用'
  await ElMessageBox.confirm(`确认${action}用户「${row.nickname}（${row.phone}）」？`, '提示')
  if (enable) {
    await enableUser(row.id)
  } else {
    await disableUser(row.id)
  }
  ElMessage.success(`已${action}`)
  load()
}

onMounted(load)
</script>

<style scoped>
.pager {
  margin-top: 16px;
  justify-content: flex-end;
}
</style>
