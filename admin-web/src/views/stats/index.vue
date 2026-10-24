<template>
  <div class="page-card">
    <el-card>
      <template #header>数据统计</template>
      <el-empty description="报表看板规划于 P4 阶段实现（计划书 4.1.1）" />
      <p class="hint">规划内容：订单量趋势、平均响应时长、完成率、好评率、工程师接单排行、区域热力图。</p>
    </el-card>
  </div>
</template>

<script setup lang="ts"></script>

<style scoped>
.hint {
  color: #999;
  font-size: 13px;
}
</style>
