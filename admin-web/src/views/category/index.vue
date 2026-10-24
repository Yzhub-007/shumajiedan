<template>
  <el-card class="page-card">
    <div class="table-toolbar">
      <span>设备类型与基础价格（客户发单时按此展示预估费用）</span>
      <el-button type="primary" :icon="Plus" @click="openDialog()">新增类型</el-button>
    </div>

    <el-table :data="rows" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="name" label="名称" min-width="160" />
      <el-table-column label="基础费（元）" width="130">
        <template #default="{ row }">¥{{ row.baseFee }}</template>
      </el-table-column>
      <el-table-column label="上门费（元）" width="130">
        <template #default="{ row }">¥{{ row.visitFee }}</template>
      </el-table-column>
      <el-table-column prop="sort" label="排序" width="80" />
      <el-table-column label="状态" width="90">
        <template #default="{ row }">
          <el-tag :type="row.enabled ? 'success' : 'info'">
            {{ row.enabled ? '启用' : '停用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="160" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="openDialog(row)">编辑</el-button>
          <el-button v-if="row.enabled" type="danger" size="small" @click="onDisable(row)">
            停用
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑类型' : '新增类型'" width="420px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="名称">
          <el-input v-model="form.name" placeholder="如：注塑机" />
        </el-form-item>
        <el-form-item label="基础费">
          <el-input-number v-model="form.baseFee" :min="0" :precision="2" />
        </el-form-item>
        <el-form-item label="上门费">
          <el-input-number v-model="form.visitFee" :min="0" :precision="2" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort" :min="0" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onSave">保存</el-button>
      </template>
    </el-dialog>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { createCategory, disableCategory, listCategories, updateCategory } from '../../api/modules'

const rows = ref<any[]>([])
const loading = ref(false)
const dialogVisible = ref(false)
const editing = ref(false)
let editingId: number | null = null

const form = reactive<{ name: string; baseFee: number; visitFee: number; sort: number }>({
  name: '',
  baseFee: 0,
  visitFee: 0,
  sort: 0
})

const load = async () => {
  loading.value = true
  try {
    // 树接口返回两级，这里拍平展示；TODO(2.3.3) el-tree-table 父子展示
    const tree = await listCategories()
    rows.value = flatten(tree as any[])
  } finally {
    loading.value = false
  }
}

const flatten = (nodes: any[], depth = 0): any[] =>
  nodes.flatMap((n) => [
    { ...n, name: depth ? `${'　'.repeat(depth)}└ ${n.name}` : n.name },
    ...flatten(n.children ?? [], depth + 1)
  ])

const openDialog = (row?: any) => {
  editing.value = !!row
  editingId = row?.id ?? null
  form.name = row?.name ?? ''
  form.baseFee = row?.baseFee ?? 0
  form.visitFee = row?.visitFee ?? 0
  form.sort = row?.sort ?? 0
  dialogVisible.value = true
}

const onSave = async () => {
  if (!form.name.trim()) {
    ElMessage.warning('请输入名称')
    return
  }
  if (editing.value && editingId) {
    await updateCategory(editingId, { ...form })
  } else {
    await createCategory({ ...form })
  }
  ElMessage.success('已保存')
  dialogVisible.value = false
  load()
}

const onDisable = async (row: any) => {
  await ElMessageBox.confirm(`确认停用「${row.name}」？`, '提示')
  await disableCategory(row.id)
  ElMessage.success('已停用')
  load()
}

onMounted(load)
</script>
