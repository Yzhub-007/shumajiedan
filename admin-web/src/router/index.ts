import { createRouter, createWebHistory } from 'vue-router'
import AdminLayout from '../layout/AdminLayout.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      component: () => import('../views/login/index.vue'),
      meta: { title: '登录' }
    },
    {
      path: '/',
      component: AdminLayout,
      redirect: '/dashboard',
      children: [
        {
          path: 'dashboard',
          component: () => import('../views/dashboard/index.vue'),
          meta: { title: '工作台', icon: 'Odometer' }
        },
        {
          path: 'orders',
          component: () => import('../views/order/index.vue'),
          meta: { title: '工单管理', icon: 'Tickets' }
        },
        {
          path: 'engineers',
          component: () => import('../views/engineer/index.vue'),
          meta: { title: '工程师审核', icon: 'Avatar' }
        },
        {
          path: 'categories',
          component: () => import('../views/category/index.vue'),
          meta: { title: '价格配置', icon: 'PriceTag' }
        },
        {
          path: 'stats',
          component: () => import('../views/stats/index.vue'),
          meta: { title: '数据统计', icon: 'DataAnalysis' }
        }
      ]
    }
  ]
})

router.beforeEach((to) => {
  const token = localStorage.getItem('admin_token')
  if (to.path !== '/login' && !token) return '/login'
  if (to.path === '/login' && token) return '/'
  // TODO(2.3.1) RBAC 权限路由：按管理员角色过滤菜单与按钮
})

router.afterEach((to) => {
  document.title = `${to.meta.title ?? ''} - 机器报修平台管理后台`
})

export default router
