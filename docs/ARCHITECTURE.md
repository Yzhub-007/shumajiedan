# 架构设计文档

对应计划书第 4、5、6 节。本文档描述当前代码框架的实际落法。

## 1. 总体架构

```
Flutter App(客户/工程师双身份)      Vue3 管理后台
        │  REST + STOMP(/ws)          │  REST
        └──────────┬───────────────────┘
                   ▼
            Spring Boot 单体 (com.repairhub)
   ┌─────────┬─────────┬──────────┬─────────┬────────┬──────────┐
   │  auth   │  user   │  order   │ dispatch│ notify │  admin   │
   │ 认证/JWT │ 用户资料 │ 工单/状态机│ 派单/位置 │ 通知/推送│ 后台管理  │
   └─────────┴─────────┴──────────┴─────────┴────────┴──────────┘
        │            │            │             │
   PostgreSQL     Redis       RabbitMQ        MinIO
   (+PostGIS)  (GEO/锁/验证码)  (事件,预留)    (图片视频)
                   │
        thirdparty: 短信/地图/OSS 适配器（Mock 可切换）
```

模块间调用规则（保持无环，便于后期拆分微服务）：

- `order → dispatch` **不直接调用**：工单创建/状态变更通过 Spring 事件（`OrderCreatedEvent`、状态变更事件）发布，`dispatch`/`notify` 监听。
- `dispatch` 可读 `order` 的 Repository，写状态时走**条件更新**（乐观锁语义），不依赖 order 的 Service。
- `user ↔ dispatch` 存在一处包级引用（工程师端位置上报/上下线直接写 Redis GEO），拆分微服务时以"位置上报"接口为界抽出位置服务。

## 2. 后端模块划分（com.repairhub）

| 包 | 职责 | 计划书对应 |
|---|---|---|
| `common` | 统一响应 `ApiResponse`、错误码、全局异常、分页、BaseEntity、GeoUtils、Redis/Security/WebSocket/OpenAPI 配置 | 5 架构 |
| `auth` | 短信验证码登录、JWT 签发/刷新、过滤器 | 7.认证 |
| `user` | 用户/客户企业资料/地址、工程师资质与审核状态、上下线 | 7.客户端/工程师端 |
| `order` | 工单 CRUD、**显式状态机**、报价、维修报告、评价、设备类型字典 | 2.2 状态机 |
| `dispatch` | 工程师位置（Redis GEO）、工单池、抢单（Redis 锁+条件更新）、派单记录 | 5.1 关键技术点 1/2 |
| `notify` | 站内信、推送适配器（接口+Mock）、WebSocket 订单事件广播 | 3.1 公共 |
| `payment` | V1.1 预留：支付/钱包接口占位 | 3.2 |
| `admin` | 管理员登录、工程师审核、工单指派/改派/关闭、价格配置、统计 | 7.管理后台 |
| `thirdparty` | 短信、OSS(MinIO 预签名)、地图 适配器，均提供 Mock 实现 | 4.1 选型 |

## 3. 工单状态机（核心）

状态与转移见 `backend/.../order/state/OrderStateMachine.java`（唯一事实来源，数据库 `order_status_logs` 记录全部流转）。

| 当前状态 | 动作 | 目标状态 | 允许角色 |
|---|---|---|---|
| PENDING | GRAB 抢单 | ACCEPTED | ENGINEER / ADMIN |
| PENDING | ASSIGN 指派 | ACCEPTED | ADMIN |
| PENDING / ACCEPTED | CANCEL 取消 | CANCELLED | CUSTOMER / ADMIN / ENGINEER(仅ACCEPTED) |
| ACCEPTED | DEPART 出发 | ON_THE_WAY | ENGINEER |
| ON_THE_WAY | ARRIVE 到达签到 | ARRIVED | ENGINEER |
| ARRIVED | START_REPAIR 无报价直接维修 | REPAIRING | ENGINEER |
| ARRIVED | QUOTE_ACCEPT 客户确认报价 | REPAIRING | CUSTOMER |
| REPAIRING | FINISH 完工提交 | PENDING_CONFIRM | ENGINEER |
| REPAIRING | CLOSE_UNRESOLVED 无法修复 | CLOSED_UNRESOLVED | ENGINEER / ADMIN |
| PENDING_CONFIRM | CONFIRM_FINISH 验收通过 | PENDING_PAYMENT（V1.1 开启支付时）/ COMPLETED | CUSTOMER |
| PENDING_CONFIRM | REJECT_FINISH 退回返修 | REPAIRING | CUSTOMER |
| PENDING_PAYMENT | PAY 支付 | COMPLETED | CUSTOMER |
| COMPLETED | REVIEW 评价 | REVIEWED | CUSTOMER / ENGINEER |

- MVP 配置 `app.order.payment-enabled=false`，验收通过直接到 COMPLETED。
- 非法转移抛 `ORDER_STATE_ILLEGAL`，计划书 12 验收标准要求 100% 路径有测试 → `OrderStateMachineTest`。

## 4. 关键技术点落法

1. **附近工程师**：工程师端 `POST /api/engineer/location` → `GEOADD engineers:online`（每次必写）；DB 侧 60 秒节流落库（Redis SETNX 窗口）。发单事件 → `GEOSEARCH` 半径内工程师 → 技能匹配（skill_tags ∩ 设备类型，未填技能默认可派）→ 去重后推送并写 `dispatch_records`。DB 侧 `engineer_profiles.location` 为 PostGIS 生成列（GIST 索引），用于离线统计。
2. **抢单防并发**：`GrabService` 先 `SET lock:order:{id} NX EX 10`，再执行条件更新 `UPDATE orders SET ... WHERE id=? AND status='PENDING'`（`@Modifying`），更新行数=1 才算抢单成功。
3. **超时处理（已实现）**：`OrderTimeoutScheduler` 监听状态变更事件，把（工单,阶段,到期时间）写入 Redis ZSet，`@Scheduled` 每 30s 扫描到期项（先原子 ZREM 再处理，多实例安全）。规则：PENDING 15 分钟无人接单 → 半径翻倍重派；ACCEPTED 30 分钟未出发 → 提醒，60 分钟 → RELEASE 回单池（清空 engineer_id）；PENDING_CONFIRM 48 小时 → SYSTEM 角色自动验收。阈值见 `app.order.*` 配置。
4. **实时推送**：STOMP `/ws`，状态变更后广播 `/topic/order/{id}`（事务提交后 `@TransactionalEventListener`）；App 端 `RealtimeService`（stomp_dart_client）订阅并自动刷新详情页，后台时走系统推送（`PushSender` 接口，Mock 打日志，后续换极光/APNs）。
5. **链路追踪**：`RequestIdFilter` 透传/生成 `X-Request-Id`，写入 MDC（日志格式含 requestId）与响应头；写接口幂等（requestId 去重）在 V1.1 支付回调时落地。
6. **文件上传**：开发环境 `POST /api/upload` multipart 落盘 + `/uploads/**` 静态访问（mock provider）；生产切换 MinIO/云 OSS 预签名直传（`POST /api/upload/presign` 已就绪）。
7. **统计报表**：`/admin/stats/overview` 输出状态分布、近 14 日趋势、平均接单时长（近 30 天）、完成率、平均评分、工程师 Top10；后台 ECharts 渲染。

## 5. 数据库

- DDL：`backend/src/main/resources/db/migration/V1__init.sql`（Flyway），与计划书第 6 节一致，并补充索引与种子数据。
- 实体仅用 `Long` 外键（不建 `@ManyToOne` 对象关系），符合模块化单体边界，方便后续拆表拆库。

## 6. 前端/移动端分层

- **mobile**：`core`（配置/主题/路由/网络/存储）→ `features/{auth,customer,engineer,notification}`（screen + riverpod controller）→ `shared`（模型与通用组件）。登录后按 `UserRole` 决定首页（客户端 / 工程师端），对应计划书 2.1 建议"一个 App 两种身份"。网络层含 401 refreshToken 静默续期；`RealtimeService`（STOMP）驱动详情页实时刷新；上传走 `/api/upload`（mock）或 OSS 预签名。
- **admin-web**：`api`（axios 封装 + 模块化接口）→ `stores`（Pinia 用户态）→ `router`（登录守卫 + 布局内嵌页面）→ `views`（dashboard / engineer 审核 / order / category 价格 / stats）。
