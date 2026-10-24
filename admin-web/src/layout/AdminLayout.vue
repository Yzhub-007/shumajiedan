<template>
  <el-container class="layout">
    <el-aside width="220px" class="aside">
      <div class="logo">🔧 机器报修平台</div>
      <el-menu
        :default-active="$route.path"
        router
        background-color="#1d2935"
        text-color="#a7b1c2"
        active-text-color="#ffffff"
      >
        <el-menu-item v-for="item in menus" :key="item.path" :index="item.path">
          <el-icon><component :is="item.icon" /></el-icon>
          <span>{{ item.title }}</span>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <el-container>
      <el-header class="header">
        <div />
        <el-dropdown @command="onCommand">
          <span class="user">
            <el-icon class="user-icon"><UserFilled /></el-icon>
            {{ userStore.username || '管理员' }}
            <el-icon><ArrowDown /></el-icon>
          </span>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="logout">退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </el-header>
      <el-main class="main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '../stores/user'

const router = useRouter()
const userStore = useUserStore()

const menus = computed(() =>
  router.options.routes
    .find((r) => r.path === '/')
    ?.children?.map((c) => ({
      path: `/${c.path}`,
      title: c.meta?.title as string,
      icon: c.meta?.icon as string
    })) ?? []
)

const onCommand = (command: string) => {
  if (command === 'logout') {
    userStore.logout()
    router.push('/login')
  }
}
</script>

<style scoped>
.layout {
  height: 100%;
}
.aside {
  background: #1d2935;
}
.logo {
  height: 56px;
  line-height: 56px;
  text-align: center;
  color: #fff;
  font-weight: 600;
  letter-spacing: 1px;
}
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #eee;
  background: #fff;
}
.user {
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
}
.user-icon {
  margin-right: 4px;
}
.main {
  background: #f5f7fa;
  padding: 0;
}
</style>
