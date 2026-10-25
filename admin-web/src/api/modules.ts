import http from './http'

// ---------- 认证 ----------
export const adminLogin = (data: { username: string; password: string }) =>
  http.post('/admin/auth/login', data)

// ---------- 工程师审核 ----------
export const listEngineers = (params: { verifyStatus?: string; page: number; size: number }) =>
  http.get('/admin/engineers', { params })

export const approveEngineer = (userId: number) =>
  http.post(`/admin/engineers/${userId}/approve`)

export const rejectEngineer = (userId: number, reason: string) =>
  http.post(`/admin/engineers/${userId}/reject`, { reason })

// ---------- 工单 ----------
export interface PageResult<T> {
  list: T[]
  total: number
  page: number
  size: number
}

export interface OrderRow {
  id: number
  orderNo: string
  customerId: number
  engineerId: number | null
  engineerName: string | null
  deviceCategoryName: string | null
  faultDesc: string
  addressText: string
  urgencyLabel: string | null
  status: string
  statusLabel: string
  quoteAmount: number | null
  finalAmount: number | null
  createdAt: string
}

export const listOrders = (params: {
  status?: string
  keyword?: string
  page: number
  size: number
}) => http.get<never, PageResult<OrderRow>>('/admin/orders', { params })

export const assignOrder = (id: number, engineerId: number) =>
  http.post(`/admin/orders/${id}/assign`, { engineerId })

export const reassignOrder = (id: number, engineerId: number) =>
  http.post(`/admin/orders/${id}/reassign`, { engineerId })

export const closeOrder = (id: number, reason: string) =>
  http.post(`/admin/orders/${id}/close`, { reason })

// 工单详情复用客户端详情接口（ADMIN 角色可读任意工单）
export interface OrderDetail {
  order: OrderRow & { faultDesc: string; mediaUrls?: string[]; estimate?: number }
  statusLogs: { fromStatusLabel: string | null; toStatusLabel: string; remark: string | null; createdAt: string }[]
  quotes: { id: number; laborFee: number; partsFee: number; total: number; status: string; createdAt: string }[]
  report: { diagnosis: string; solution: string; beforePhotos: string[]; afterPhotos: string[] } | null
  engineer: { userId: number; realName: string; phone: string; ratingAvg: number; orderCount: number } | null
}

export const getOrderDetail = (id: number) => http.get<never, OrderDetail>(`/api/orders/${id}`)

// 附近在线工程师候选人（指派/改派选人）
export interface NearbyEngineer {
  userId: number
  realName: string
  distanceM: number
  ratingAvg: number
  orderCount: number
  onlineStatus: boolean
}

export const listNearbyEngineers = (id: number) =>
  http.get<never, NearbyEngineer[]>(`/admin/orders/${id}/nearby-engineers`)

// ---------- 设备类型与价格 ----------
export interface CategoryRow {
  id: number
  parentId: number | null
  name: string
  baseFee: number
  visitFee: number
  sort: number
  enabled: boolean
}

export const listCategories = () =>
  http.get<never, CategoryRow[]>('/admin/device-categories')

export const createCategory = (data: Partial<CategoryRow>) =>
  http.post('/admin/device-categories', data)

export const updateCategory = (id: number, data: Partial<CategoryRow>) =>
  http.put(`/admin/device-categories/${id}`, data)

export const disableCategory = (id: number) =>
  http.delete(`/admin/device-categories/${id}`)

// ---------- 统计 ----------
export const statsOverview = () => http.get('/admin/stats/overview')
