<template>
  <el-container class="layout">
    <el-aside width="232px" class="aside">
      <div class="logo">
        <div class="logo-mark">🔧</div>
        <div class="logo-text">
          <div class="logo-title">机器报修平台</div>
          <div class="logo-sub">管理控制台</div>
        </div>
      </div>
      <el-menu
        class="menu"
        :default-active="$route.path"
        router
      >
        <el-menu-item
          v-for="item in menus"
          :key="item.path"
          :index="item.path"
        >
          <el-icon><component :is="item.icon" /></el-icon>
          <span>{{ item.title }}</span>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <el-container>
      <el-header class="header">
        <div class="page-title">{{ pageTitle }}</div>
        <el-dropdown @command="onCommand">
          <span class="user">
            <span class="user-avatar">
              <el-icon><UserFilled /></el-icon>
            </span>
            {{ userStore.username || '管理员' }}
            <el-icon class="user-arrow"><ArrowDown /></el-icon>
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
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '../stores/user'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const pageTitle = computed(() => (route.meta?.title as string) ?? '')

const menus = computed(() =>
  router.options.routes
    .find((r) => r.path === '/')
    ?.children?.filter((c) => !c.meta?.superAdminOnly || userStore.isSuperAdmin)
    .map((c) => ({
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

/* 亮色侧栏（Apple 设置 / Finder 风格） */
.aside {
  background: #fbfbfd;
  border-right: 1px solid rgba(0, 0, 0, 0.06);
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  height: 64px;
  padding: 0 18px;
}
.logo-mark {
  width: 34px;
  height: 34px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  background: linear-gradient(135deg, #1e5aa8, #3e7bc8);
  border-radius: 10px;
}
.logo-title {
  font-size: 15px;
  font-weight: 700;
  color: #1d1d1f;
  line-height: 1.2;
}
.logo-sub {
  font-size: 11px;
  color: #86868b;
  margin-top: 1px;
}

.menu {
  border-right: none;
  background: transparent;
  padding: 4px 0;
}
.menu :deep(.el-menu-item) {
  height: 44px;
  line-height: 44px;
  margin: 2px 10px;
  border-radius: 10px;
  color: #424245;
  transition: background-color 0.15s ease, color 0.15s ease;
}
.menu :deep(.el-menu-item:hover) {
  background: #f0f0f3;
}
.menu :deep(.el-menu-item.is-active) {
  background: rgba(30, 90, 168, 0.1);
  color: #1e5aa8;
  font-weight: 600;
}

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 60px;
  background: #ffffff;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}
.page-title {
  font-size: 16px;
  font-weight: 700;
  color: #1d1d1f;
}
.user {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 5px 10px;
  border-radius: 999px;
  color: #1d1d1f;
  font-size: 13.5px;
  outline: none;
  transition: background-color 0.15s ease;
}
.user:hover {
  background: #f5f5f7;
}
.user-avatar {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: rgba(30, 90, 168, 0.1);
  color: #1e5aa8;
}
.user-arrow {
  font-size: 12px;
  color: #86868b;
}

.main {
  background: #f5f5f7;
  padding: 0;
}
</style>
