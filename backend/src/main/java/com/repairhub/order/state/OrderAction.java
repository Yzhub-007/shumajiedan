package com.repairhub.order.state;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 工单动作（状态机的输入）。对应 API 各操作端点。
 */
@Getter
@AllArgsConstructor
public enum OrderAction {

    GRAB("抢单"),
    ASSIGN("后台指派"),
    CANCEL("取消工单"),
    RELEASE("超时释放回单池"),
    DEPART("出发"),
    ARRIVE("到达签到"),
    START_REPAIR("开始维修"),
    QUOTE_ACCEPT("确认报价"),
    FINISH("完工提交"),
    CLOSE_UNRESOLVED("无法修复关闭"),
    CONFIRM_FINISH("验收通过"),
    REJECT_FINISH("验收退回"),
    PAY("支付"),
    REVIEW("评价");

    private final String label;
}
