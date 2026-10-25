-- 设备类型支持手动输入：字典关联改为可空，新增用户输入文本快照
ALTER TABLE orders ALTER COLUMN device_category_id DROP NOT NULL;
ALTER TABLE orders ADD COLUMN device_category_input VARCHAR(50);
