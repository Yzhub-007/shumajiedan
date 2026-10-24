-- =====================================================================
-- 机器报修接单平台 V1 初始化（对应计划书第 6 节数据库设计）
-- 枚举字段统一用 VARCHAR，与 JPA @Enumerated(EnumType.STRING) 对齐
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- ---------------------------------------------------------------
-- 用户（客户/工程师/系统管理员共用账户）
-- ---------------------------------------------------------------
CREATE TABLE users (
    id            BIGSERIAL PRIMARY KEY,
    phone         VARCHAR(20)  NOT NULL UNIQUE,
    password_hash VARCHAR(100),
    nickname      VARCHAR(50),
    avatar_url    VARCHAR(500),
    role          VARCHAR(20)  NOT NULL,               -- CUSTOMER / ENGINEER / ADMIN / SYSTEM
    status        VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_role ON users(role);

-- 客户企业信息
CREATE TABLE customer_profiles (
    user_id      BIGINT PRIMARY KEY REFERENCES users(id),
    company_name VARCHAR(100),
    contact_name VARCHAR(50),
    industry     VARCHAR(50),
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 客户地址
CREATE TABLE addresses (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT NOT NULL REFERENCES users(id),
    label      VARCHAR(50),
    province   VARCHAR(50),
    city       VARCHAR(50),
    district   VARCHAR(50),
    detail     VARCHAR(200),
    lng        DOUBLE PRECISION NOT NULL DEFAULT 0,
    lat        DOUBLE PRECISION NOT NULL DEFAULT 0,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_addresses_user ON addresses(user_id);

-- 工程师资料与认证
CREATE TABLE engineer_profiles (
    user_id           BIGINT PRIMARY KEY REFERENCES users(id),
    real_name         VARCHAR(50),
    id_card_no        VARCHAR(100),
    id_card_front_url VARCHAR(500),
    id_card_back_url  VARCHAR(500),
    cert_urls         JSONB NOT NULL DEFAULT '[]',
    skill_tags        JSONB NOT NULL DEFAULT '[]',
    service_radius_km INT NOT NULL DEFAULT 10,
    verify_status     VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING / APPROVED / REJECTED
    reject_reason     VARCHAR(500),
    rating_avg        NUMERIC(3,2) NOT NULL DEFAULT 5.00,
    order_count       INT NOT NULL DEFAULT 0,
    online_status     BOOLEAN NOT NULL DEFAULT FALSE,
    last_lng          DOUBLE PRECISION NOT NULL DEFAULT 0,
    last_lat          DOUBLE PRECISION NOT NULL DEFAULT 0,
    last_location_at  TIMESTAMP,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- PostGIS 生成列 + GIST 索引（计划书第 6 节索引要点），由 last_lng/last_lat 派生
ALTER TABLE engineer_profiles
    ADD COLUMN location geography(point, 4326)
    GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(last_lng, last_lat), 4326)::geography) STORED;
CREATE INDEX idx_engineer_location ON engineer_profiles USING GIST (location);

-- 设备类型字典 + 基础价
CREATE TABLE device_categories (
    id         BIGSERIAL PRIMARY KEY,
    parent_id  BIGINT REFERENCES device_categories(id),
    name       VARCHAR(50) NOT NULL,
    base_fee   NUMERIC(10,2) NOT NULL DEFAULT 0,
    visit_fee  NUMERIC(10,2) NOT NULL DEFAULT 0,
    sort       INT NOT NULL DEFAULT 0,
    enabled    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 工单
CREATE TABLE orders (
    id                 BIGSERIAL PRIMARY KEY,
    order_no           VARCHAR(32) NOT NULL UNIQUE,
    customer_id        BIGINT NOT NULL REFERENCES users(id),
    engineer_id        BIGINT REFERENCES users(id),
    device_category_id BIGINT NOT NULL REFERENCES device_categories(id),
    device_brand       VARCHAR(50),
    device_model       VARCHAR(50),
    fault_desc         VARCHAR(2000) NOT NULL,
    media_urls         JSONB NOT NULL DEFAULT '[]',
    address_id         BIGINT REFERENCES addresses(id),
    address_snapshot   JSONB NOT NULL DEFAULT '{}',
    lng                DOUBLE PRECISION NOT NULL DEFAULT 0,
    lat                DOUBLE PRECISION NOT NULL DEFAULT 0,
    urgency            VARCHAR(20) NOT NULL DEFAULT 'NORMAL',   -- NORMAL / URGENT / CRITICAL
    expect_time        TIMESTAMP,
    status             VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    quote_amount       NUMERIC(10,2),
    final_amount       NUMERIC(10,2),
    platform_fee       NUMERIC(10,2),
    accepted_at        TIMESTAMP,
    arrived_at         TIMESTAMP,
    repair_started_at  TIMESTAMP,
    finished_at        TIMESTAMP,
    confirmed_at       TIMESTAMP,
    paid_at            TIMESTAMP,
    cancelled_at       TIMESTAMP,
    cancel_reason      VARCHAR(500),
    cancel_by          BIGINT,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_orders_status_created ON orders(status, created_at);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_engineer ON orders(engineer_id);

-- 工单状态流水
CREATE TABLE order_status_logs (
    id            BIGSERIAL PRIMARY KEY,
    order_id      BIGINT NOT NULL REFERENCES orders(id),
    from_status   VARCHAR(30),
    to_status     VARCHAR(30) NOT NULL,
    operator_id   BIGINT,
    operator_role VARCHAR(20),
    remark        VARCHAR(200),
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_status_logs_order ON order_status_logs(order_id);

-- 报价
CREATE TABLE order_quotes (
    id          BIGSERIAL PRIMARY KEY,
    order_id    BIGINT NOT NULL REFERENCES orders(id),
    engineer_id BIGINT NOT NULL REFERENCES users(id),
    labor_fee   NUMERIC(10,2) NOT NULL DEFAULT 0,
    parts_fee   NUMERIC(10,2) NOT NULL DEFAULT 0,
    parts_detail JSONB NOT NULL DEFAULT '[]',
    total       NUMERIC(10,2) NOT NULL DEFAULT 0,
    status      VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING / ACCEPTED / REJECTED
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_quotes_order ON order_quotes(order_id);

-- 维修记录
CREATE TABLE repair_reports (
    id             BIGSERIAL PRIMARY KEY,
    order_id       BIGINT NOT NULL REFERENCES orders(id),
    diagnosis      VARCHAR(2000),
    solution       VARCHAR(2000),
    before_photos  JSONB NOT NULL DEFAULT '[]',
    after_photos   JSONB NOT NULL DEFAULT '[]',
    parts_replaced JSONB NOT NULL DEFAULT '[]',
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_reports_order ON repair_reports(order_id);

-- 评价（双向：客户评工程师 / 工程师评客户）
CREATE TABLE reviews (
    id          BIGSERIAL PRIMARY KEY,
    order_id    BIGINT NOT NULL REFERENCES orders(id),
    from_user_id BIGINT NOT NULL REFERENCES users(id),
    to_user_id  BIGINT NOT NULL REFERENCES users(id),
    score       INT NOT NULL CHECK (score BETWEEN 1 AND 5),
    tags        JSONB NOT NULL DEFAULT '[]',
    content     VARCHAR(1000),
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_reviews_order_from UNIQUE (order_id, from_user_id)
);

-- 派单记录：谁被推送了、谁抢了、谁拒了
CREATE TABLE dispatch_records (
    id         BIGSERIAL PRIMARY KEY,
    order_id   BIGINT NOT NULL REFERENCES orders(id),
    engineer_id BIGINT NOT NULL REFERENCES users(id),
    type       VARCHAR(20) NOT NULL,   -- PUSH / GRAB / ASSIGN / REJECT
    distance_m INT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_dispatch_order ON dispatch_records(order_id);

-- 支付（V1.1）
CREATE TABLE payments (
    id           BIGSERIAL PRIMARY KEY,
    order_id     BIGINT NOT NULL REFERENCES orders(id),
    amount       NUMERIC(10,2) NOT NULL,
    channel      VARCHAR(20),            -- WECHAT / ALIPAY
    trade_no     VARCHAR(64),
    status       VARCHAR(20) NOT NULL DEFAULT 'CREATED',
    paid_at      TIMESTAMP,
    raw_callback JSONB,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE wallets (
    user_id      BIGINT PRIMARY KEY REFERENCES users(id),
    balance      NUMERIC(12,2) NOT NULL DEFAULT 0,
    frozen       NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_income NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE withdrawals (
    id           BIGSERIAL PRIMARY KEY,
    user_id      BIGINT NOT NULL REFERENCES users(id),
    amount       NUMERIC(12,2) NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    account_info JSONB NOT NULL DEFAULT '{}',
    reviewed_by  BIGINT,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 通知
CREATE TABLE notifications (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT NOT NULL REFERENCES users(id),
    type       VARCHAR(30) NOT NULL,
    title      VARCHAR(100) NOT NULL,
    body       VARCHAR(500),
    data       JSONB NOT NULL DEFAULT '{}',
    read_at    TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_notifications_user ON notifications(user_id, created_at);

-- 后台管理员与操作日志
CREATE TABLE admins (
    id            BIGSERIAL PRIMARY KEY,
    username      VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(100) NOT NULL,
    role          VARCHAR(20) NOT NULL DEFAULT 'SUPER_ADMIN',
    status        VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admin_op_logs (
    id         BIGSERIAL PRIMARY KEY,
    admin_id   BIGINT NOT NULL,
    action     VARCHAR(50) NOT NULL,
    target     VARCHAR(100),
    detail     JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------
-- 种子数据：后台管理员（admin / admin123，BCrypt）与设备类型示例
-- ---------------------------------------------------------------
INSERT INTO admins (username, password_hash, role) VALUES
    ('admin', '$2b$10$UnB5CgLWUQFgIbGYlzBQnOPw0B2P0wyiT66cz9WRuwqrztWWQmhHW', 'SUPER_ADMIN');

INSERT INTO device_categories (name, base_fee, visit_fee, sort) VALUES
    ('注塑机',       300.00, 80.00, 1),
    ('CNC 加工中心', 400.00, 100.00, 2),
    ('制冷设备',     260.00, 80.00, 3),
    ('空压机',       240.00, 80.00, 4),
    ('餐饮厨房设备', 180.00, 60.00, 5);
