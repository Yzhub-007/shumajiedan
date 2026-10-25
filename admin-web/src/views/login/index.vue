<template>
  <div class="login-page">
    <div class="login-card">
      <div class="logo-mark">🔧</div>
      <h2 class="title">机器报修平台</h2>
      <div class="subtitle">管理控制台</div>
      <el-form :model="form" size="large" @keyup.enter="onLogin">
        <el-form-item>
          <el-input v-model="form.username" placeholder="用户名" :prefix-icon="User" />
        </el-form-item>
        <el-form-item>
          <el-input
            v-model="form.password"
            type="password"
            placeholder="密码"
            show-password
            :prefix-icon="Lock"
          />
        </el-form-item>
        <el-button type="primary" class="login-btn" :loading="loading" @click="onLogin">
          登 录
        </el-button>
        <div class="tip">默认账号 admin / admin123（请上线前修改）</div>
      </el-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { useUserStore } from '../../stores/user'

const router = useRouter()
const userStore = useUserStore()

const form = reactive({ username: 'admin', password: '' })
const loading = ref(false)

const onLogin = async () => {
  if (!form.username || !form.password) {
    ElMessage.warning('请输入用户名和密码')
    return
  }
  loading.value = true
  try {
    await userStore.login(form.username, form.password)
    router.push('/')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background:
    radial-gradient(1200px 600px at 15% 0%, rgba(62, 123, 200, 0.35), transparent 60%),
    radial-gradient(1000px 500px at 100% 100%, rgba(30, 90, 168, 0.5), transparent 55%),
    linear-gradient(160deg, #14243c 0%, #1e5aa8 55%, #16406f 100%);
}

.login-card {
  width: 400px;
  padding: 44px 36px 32px;
  background: rgba(255, 255, 255, 0.96);
  border-radius: 20px;
  box-shadow: 0 24px 80px rgba(0, 0, 0, 0.35);
}

.logo-mark {
  width: 56px;
  height: 56px;
  margin: 0 auto 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 26px;
  background: linear-gradient(135deg, #1e5aa8, #3e7bc8);
  border-radius: 16px;
  box-shadow: 0 8px 24px rgba(30, 90, 168, 0.35);
}

.title {
  text-align: center;
  margin: 0;
  font-size: 20px;
  font-weight: 700;
  color: #1d1d1f;
  letter-spacing: 0.2px;
}
.subtitle {
  text-align: center;
  margin: 4px 0 26px;
  font-size: 13px;
  color: #86868b;
}

.login-btn {
  width: 100%;
  height: 44px;
  margin-top: 4px;
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 4px;
}
.tip {
  margin-top: 14px;
  text-align: center;
  color: #a1a1a6;
  font-size: 12px;
}
</style>
