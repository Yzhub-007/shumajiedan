<template>
  <div class="page-card">
    <el-row :gutter="16">
      <el-col :span="6">
        <el-card>
          <template #header>平均接单时长（近30天）</template>
          <div class="num">{{ overview.avgAcceptMinutes ?? '-' }} <span class="unit">分钟</span></div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <template #header>完成率</template>
          <div class="num ok">{{ overview.completionRate ?? '-' }}<span class="unit">%</span></div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <template #header>平台平均评分</template>
          <div class="num warn">{{ overview.avgRating ?? '-' }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <template #header>累计工单</template>
          <div class="num">{{ overview.totalOrders ?? '-' }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card class="mt">
      <template #header>近 14 日订单量趋势</template>
      <div ref="trendChart" class="chart"></div>
    </el-card>

    <el-card class="mt">
      <template #header>工程师接单排行 Top10（按完成单数）</template>
      <el-table :data="overview.engineerRanking ?? []" border size="small">
        <el-table-column type="index" label="#" width="60" />
        <el-table-column prop="realName" label="姓名" min-width="120" />
        <el-table-column prop="orderCount" label="完成单数" width="110" />
        <el-table-column prop="ratingAvg" label="评分" width="90" />
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { nextTick, onMounted, ref } from 'vue'
import * as echarts from 'echarts'
import { statsOverview } from '../../api/modules'

const overview = ref<Record<string, any>>({})
const trendChart = ref<HTMLDivElement>()

onMounted(async () => {
  overview.value = await statsOverview()
  await nextTick()
  renderTrend()
})

const renderTrend = () => {
  if (!trendChart.value) return
  const trend: { date: string; count: number }[] = overview.value.trend ?? []
  const chart = echarts.init(trendChart.value)
  chart.setOption({
    grid: { left: 40, right: 20, top: 20, bottom: 30 },
    tooltip: { trigger: 'axis' },
    xAxis: { type: 'category', data: trend.map((t) => t.date.slice(5)) },
    yAxis: { type: 'value', minInterval: 1 },
    series: [
      {
        type: 'line',
        smooth: true,
        data: trend.map((t) => t.count),
        areaStyle: { opacity: 0.15 },
        itemStyle: { color: '#1e5aa8' }
      }
    ]
  })
  window.addEventListener('resize', () => chart.resize())
}
</script>

<style scoped>
.num {
  font-size: 30px;
  font-weight: 700;
}
.num .unit {
  font-size: 14px;
  color: #999;
  font-weight: 400;
}
.num.ok {
  color: #67c23a;
}
.num.warn {
  color: #e6a23c;
}
.mt {
  margin-top: 16px;
}
.chart {
  height: 300px;
}
</style>
