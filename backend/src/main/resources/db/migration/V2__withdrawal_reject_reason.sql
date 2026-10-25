-- V2：提现审核拒绝原因（RBAC/支付结算 V1.1 能力）
ALTER TABLE withdrawals ADD COLUMN reject_reason VARCHAR(200);
