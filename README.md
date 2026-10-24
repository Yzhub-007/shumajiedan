# 机器报修接单平台（RepairHub）

> 工业设备维修版的"滴滴打车"：客户发布机器故障工单 → 平台派单/工程师抢单 → 上门维修 → 验收评价 → 线上结算。

详细业务规划见 [项目计划书-机器报修接单平台.md](./项目计划书-机器报修接单平台.md)，架构说明见 [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)。

## 技术栈（按计划书 4.1 推荐方案）

| 端 | 技术 | 说明 |
|---|---|---|
| 后端 | Java 17 + Spring Boot 3.3 + Spring Security(JWT) + Spring Data JPA | 模块化单体，按模块分包 |
| 数据库 | PostgreSQL 16 + PostGIS | Flyway 管理迁移 |
| 中间件 | Redis 7（GEO/分布式锁/验证码）、RabbitMQ 3.13（异步事件，预留）、MinIO（对象存储） | |
| 移动端 | Flutter 3.x + Riverpod + go_router + dio | 客户端/工程师端同一个 App，两种身份 |
| 管理后台 | Vue 3 + Vite + TypeScript + Element Plus + Pinia | |
| 实时 | STOMP over WebSocket（`/ws`），订阅 `/topic/order/{id}` | |

## 目录结构

```
项目/
├── 项目计划书-机器报修接单平台.md   # 原始计划书
├── docs/                  # 架构与开发文档
├── backend/               # Spring Boot 后端（模块化单体）
│   └── src/main/java/com/repairhub/{common,auth,user,order,dispatch,notify,payment,admin,thirdparty}
├── mobile/                # Flutter App（客户 + 工程师双身份）
│   └── lib/{core,shared,features/{auth,customer,engineer,notification}}
├── admin-web/             # Vue3 管理后台
└── docker-compose.yml     # 本地中间件：PostGIS / Redis / RabbitMQ / MinIO
```

## 快速开始

### 1. 启动本地中间件（需 Docker）

```bash
docker compose up -d postgres redis rabbitmq minio
# RabbitMQ 控制台 http://localhost:15672 (guest/guest)
# MinIO 控制台 http://localhost:9001 (minioadmin/minioadmin)
```

### 2. 后端（需 JDK 17 + Maven 3.9）

```bash
cd backend
mvn spring-boot:run
# 接口文档 http://localhost:8080/swagger-ui.html
```

首次启动 Flyway 自动建表并写入种子数据：
- 后台管理员：`admin / admin123`（`admins` 表，登录 `/admin/auth/login`）
- 设备类型字典：注塑机、CNC 加工中心、制冷设备、空压机、餐饮厨房设备

### 3. 管理后台（需 Node 18+）

```bash
cd admin-web
npm install
npm run dev      # http://localhost:5173，代理 /api 与 /admin 到 8080
```

### 4. 移动端（需 Flutter 3.24+）

```bash
cd mobile
flutter create . --org com.repairhub --project-name repairhub_app   # 生成 android/ios 平台目录
flutter pub get
flutter run
```

App 内 API 地址在 `lib/core/config/app_config.dart` 配置（Android 模拟器默认 `http://10.0.2.2:8080`）。

## 当前框架状态（对应计划书里程碑）

- ✅ **P1 基础设施**：三端脚手架、统一响应/异常/JWT 鉴权、Flyway、docker-compose（M2）
- 🔨 **P2 核心开发（一）**：骨架代码已就位，业务 TODO 按计划书 WBS 编号标注（如 `TODO(2.1.5)`）
- ⬜ **P3 核心开发（二）**：派单引擎为 V0 骨架（Redis GEO + 抢单锁已实现核心路径），超时延迟队列、支付等预留

各模块内的 `TODO(编号)` 与计划书 9.x 节任务编号一一对应，可按编号认领。

## 环境要求

| 工具 | 版本 |
|---|---|
| JDK | 17+ |
| Maven | 3.9+ |
| Node.js | 18+ |
| Flutter | 3.24+ |
| Docker | 24+ |
