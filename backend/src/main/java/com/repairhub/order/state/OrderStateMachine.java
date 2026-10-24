package com.repairhub.order.state;

import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.user.entity.UserRole;

import java.util.EnumMap;
import java.util.Map;
import java.util.Set;

import static com.repairhub.order.enums.OrderStatus.ACCEPTED;
import static com.repairhub.order.enums.OrderStatus.ARRIVED;
import static com.repairhub.order.enums.OrderStatus.CANCELLED;
import static com.repairhub.order.enums.OrderStatus.CLOSED_UNRESOLVED;
import static com.repairhub.order.enums.OrderStatus.COMPLETED;
import static com.repairhub.order.enums.OrderStatus.ON_THE_WAY;
import static com.repairhub.order.enums.OrderStatus.PENDING;
import static com.repairhub.order.enums.OrderStatus.PENDING_CONFIRM;
import static com.repairhub.order.enums.OrderStatus.PENDING_PAYMENT;
import static com.repairhub.order.enums.OrderStatus.REPAIRING;
import static com.repairhub.order.enums.OrderStatus.REVIEWED;

/**
 * 工单显式状态机（计划书 2.2 / 5.1.4）。
 * 全部合法转移集中于此表：任何状态变更必须经过 validate，非法转移直接拒绝并记录。
 * 单测覆盖见 OrderStateMachineTest（验收标准：状态机 100% 路径有测试）。
 */
public final class OrderStateMachine {

    private static final Map<OrderStatus, Map<OrderAction, Transition>> TABLE = new EnumMap<>(OrderStatus.class);

    private OrderStateMachine() {
    }

    /**
     * 校验并返回目标状态；非法转移/越权抛 BizException。
     */
    public static OrderStatus validate(OrderStatus current, OrderAction action, UserRole role) {
        Transition transition = TABLE.getOrDefault(current, Map.of()).get(action);
        if (transition == null) {
            throw new BizException(ErrorCode.ORDER_STATE_ILLEGAL,
                    "工单「" + current.getLabel() + "」状态不允许执行「" + action.getLabel() + "」");
        }
        if (!transition.roles().contains(role)) {
            throw new BizException(ErrorCode.FORBIDDEN,
                    "角色「" + role.getLabel() + "」不允许执行「" + action.getLabel() + "」");
        }
        return transition.to();
    }

    /** 当前状态下可执行的动作（用于端侧按钮显隐） */
    public static Set<OrderAction> availableActions(OrderStatus current) {
        return TABLE.getOrDefault(current, Map.of()).keySet();
    }

    private static void register(OrderStatus from, OrderAction action, OrderStatus to, UserRole... roles) {
        TABLE.computeIfAbsent(from, k -> new EnumMap<>(OrderAction.class))
                .put(action, new Transition(to, Set.of(roles)));
    }

    public record Transition(OrderStatus to, Set<UserRole> roles) {
    }

    static {
        // 接单：抢单 / 后台指派
        register(PENDING, OrderAction.GRAB, ACCEPTED, UserRole.ENGINEER, UserRole.ADMIN);
        register(PENDING, OrderAction.ASSIGN, ACCEPTED, UserRole.ADMIN);

        // 取消：待接单可被客户/后台取消；已接单后工程师也可取消（触发 RELEASE 之外的责任判定）
        register(PENDING, OrderAction.CANCEL, CANCELLED, UserRole.CUSTOMER, UserRole.ADMIN);
        register(ACCEPTED, OrderAction.CANCEL, CANCELLED, UserRole.CUSTOMER, UserRole.ADMIN, UserRole.ENGINEER);

        // 超时释放：已接单超时未出发 → 自动退回待接单（计划书 2.2 超时规则）
        register(ACCEPTED, OrderAction.RELEASE, PENDING, UserRole.SYSTEM, UserRole.ADMIN);

        // 上门链路
        register(ACCEPTED, OrderAction.DEPART, ON_THE_WAY, UserRole.ENGINEER);
        register(ON_THE_WAY, OrderAction.ARRIVE, ARRIVED, UserRole.ENGINEER);

        // 到达后：无报价直接维修，或客户确认报价后进入维修
        register(ARRIVED, OrderAction.START_REPAIR, REPAIRING, UserRole.ENGINEER);
        register(ARRIVED, OrderAction.QUOTE_ACCEPT, REPAIRING, UserRole.CUSTOMER);

        // 维修中
        register(REPAIRING, OrderAction.FINISH, PENDING_CONFIRM, UserRole.ENGINEER);
        register(REPAIRING, OrderAction.CLOSE_UNRESOLVED, CLOSED_UNRESOLVED, UserRole.ENGINEER, UserRole.ADMIN);

        // 验收通过：MVP 未开支付直接完成；V1.1 开启支付后由 OrderActionService 覆写目标为 PENDING_PAYMENT
        register(PENDING_CONFIRM, OrderAction.CONFIRM_FINISH, COMPLETED, UserRole.CUSTOMER);
        register(PENDING_CONFIRM, OrderAction.REJECT_FINISH, REPAIRING, UserRole.CUSTOMER);

        // 支付（V1.1）
        register(PENDING_PAYMENT, OrderAction.PAY, COMPLETED, UserRole.CUSTOMER);

        // 评价：双方都可评价；先评者触发状态流转，后评者直接补录
        register(COMPLETED, OrderAction.REVIEW, REVIEWED, UserRole.CUSTOMER, UserRole.ENGINEER);
        register(REVIEWED, OrderAction.REVIEW, REVIEWED, UserRole.CUSTOMER, UserRole.ENGINEER);
    }
}
