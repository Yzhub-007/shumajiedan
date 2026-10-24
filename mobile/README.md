# repairhub_app（Flutter 移动端）

客户端 + 工程师端同一个 App，登录时选择身份（计划书 2.1 建议，省一半发版成本）。

## 首次运行

```bash
# 1. 生成 android/ios 平台目录（保留现有 lib 与 pubspec）
flutter create . --org com.repairhub --project-name repairhub_app

# 2. 拉依赖
flutter pub get

# 3. 运行（后端地址见 lib/core/config/app_config.dart）
flutter run
```

## 目录结构

```
lib/
├── main.dart / app.dart          # 入口与 MaterialApp.router
├── core/
│   ├── config/app_config.dart    # API 地址等环境配置
│   ├── theme/app_theme.dart
│   ├── router/app_router.dart    # 登录态守卫 + 按身份分流
│   ├── network/                  # dio 封装（token 注入、统一错误）
│   └── storage/token_storage.dart
├── shared/
│   ├── models/                   # UserRole、OrderModel 等
│   └── widgets/                  # 通用组件
└── features/
    ├── auth/                     # 登录（验证码）、身份选择
    ├── customer/                 # 首页/发单/工单列表/详情/我的
    ├── engineer/                 # 接单首页/资质认证/工单操作/我的
    └── notification/             # WebSocket 与通知页
```

## 开发约定

- 页面放 `features/<模块>/screens/`，控制器（Riverpod）放 `controllers/`，与计划书 9.2.2 脚手架任务对齐。
- 各页面的业务 TODO 用计划书 WBS 编号标注，例如 `TODO(2.2.3)` = 发布工单页完整实现。
- 接口与 `docs/ARCHITECTURE.md`、`backend` 控制器一一对应。
