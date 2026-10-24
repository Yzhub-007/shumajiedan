package com.repairhub.order.state;

import com.repairhub.common.exception.BizException;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.user.entity.UserRole;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 状态机全路径覆盖（计划书 12 验收标准：状态机 100% 路径有测试覆盖，非法转移均被拒绝）。
 */
class OrderStateMachineTest {

    // ---------- 合法转移 ----------

    @Test
    void grab_movesPendingToAccepted_forEngineer() {
        assertThat(OrderStateMachine.validate(OrderStatus.PENDING, OrderAction.GRAB, UserRole.ENGINEER))
                .isEqualTo(OrderStatus.ACCEPTED);
    }

    @Test
    void assign_movesPendingToAccepted_forAdmin() {
        assertThat(OrderStateMachine.validate(OrderStatus.PENDING, OrderAction.ASSIGN, UserRole.ADMIN))
                .isEqualTo(OrderStatus.ACCEPTED);
    }

    @Test
    void cancel_allowedFromPendingByCustomerOrAdmin() {
        assertThat(OrderStateMachine.validate(OrderStatus.PENDING, OrderAction.CANCEL, UserRole.CUSTOMER))
                .isEqualTo(OrderStatus.CANCELLED);
        assertThat(OrderStateMachine.validate(OrderStatus.PENDING, OrderAction.CANCEL, UserRole.ADMIN))
                .isEqualTo(OrderStatus.CANCELLED);
    }

    @Test
    void cancel_allowedFromAcceptedByEngineer() {
        assertThat(OrderStateMachine.validate(OrderStatus.ACCEPTED, OrderAction.CANCEL, UserRole.ENGINEER))
                .isEqualTo(OrderStatus.CANCELLED);
    }

    @Test
    void release_movesAcceptedBackToPending_forSystem() {
        assertThat(OrderStateMachine.validate(OrderStatus.ACCEPTED, OrderAction.RELEASE, UserRole.SYSTEM))
                .isEqualTo(OrderStatus.PENDING);
    }

    @Test
    void visitChain_departArriveStartRepairFinish() {
        assertThat(OrderStateMachine.validate(OrderStatus.ACCEPTED, OrderAction.DEPART, UserRole.ENGINEER))
                .isEqualTo(OrderStatus.ON_THE_WAY);
        assertThat(OrderStateMachine.validate(OrderStatus.ON_THE_WAY, OrderAction.ARRIVE, UserRole.ENGINEER))
                .isEqualTo(OrderStatus.ARRIVED);
        assertThat(OrderStateMachine.validate(OrderStatus.ARRIVED, OrderAction.START_REPAIR, UserRole.ENGINEER))
                .isEqualTo(OrderStatus.REPAIRING);
        assertThat(OrderStateMachine.validate(OrderStatus.REPAIRING, OrderAction.FINISH, UserRole.ENGINEER))
                .isEqualTo(OrderStatus.PENDING_CONFIRM);
    }

    @Test
    void quoteAccept_movesArrivedToRepairing_forCustomer() {
        assertThat(OrderStateMachine.validate(OrderStatus.ARRIVED, OrderAction.QUOTE_ACCEPT, UserRole.CUSTOMER))
                .isEqualTo(OrderStatus.REPAIRING);
    }

    @Test
    void confirmFinish_movesPendingConfirmToCompleted_forCustomer() {
        assertThat(OrderStateMachine.validate(OrderStatus.PENDING_CONFIRM, OrderAction.CONFIRM_FINISH, UserRole.CUSTOMER))
                .isEqualTo(OrderStatus.COMPLETED);
    }

    @Test
    void rejectFinish_movesPendingConfirmBackToRepairing() {
        assertThat(OrderStateMachine.validate(OrderStatus.PENDING_CONFIRM, OrderAction.REJECT_FINISH, UserRole.CUSTOMER))
                .isEqualTo(OrderStatus.REPAIRING);
    }

    @Test
    void review_allowedFromCompletedAndReviewed_byBothRoles() {
        assertThat(OrderStateMachine.validate(OrderStatus.COMPLETED, OrderAction.REVIEW, UserRole.CUSTOMER))
                .isEqualTo(OrderStatus.REVIEWED);
        assertThat(OrderStateMachine.validate(OrderStatus.REVIEWED, OrderAction.REVIEW, UserRole.ENGINEER))
                .isEqualTo(OrderStatus.REVIEWED);
    }

    @Test
    void closeUnresolved_allowedFromRepairing() {
        assertThat(OrderStateMachine.validate(OrderStatus.REPAIRING, OrderAction.CLOSE_UNRESOLVED, UserRole.ENGINEER))
                .isEqualTo(OrderStatus.CLOSED_UNRESOLVED);
    }

    // ---------- 非法转移 ----------

    @Test
    void illegalTransitions_areRejected() {
        // 未接单不能出发
        assertThatThrownBy(() -> OrderStateMachine.validate(OrderStatus.PENDING, OrderAction.DEPART, UserRole.ENGINEER))
                .isInstanceOf(BizException.class);
        // 待接单不能直接验收
        assertThatThrownBy(() -> OrderStateMachine.validate(OrderStatus.PENDING, OrderAction.CONFIRM_FINISH, UserRole.CUSTOMER))
                .isInstanceOf(BizException.class);
        // 已取消是终态
        assertThatThrownBy(() -> OrderStateMachine.validate(OrderStatus.CANCELLED, OrderAction.GRAB, UserRole.ENGINEER))
                .isInstanceOf(BizException.class);
        // 已评价不能再取消
        assertThatThrownBy(() -> OrderStateMachine.validate(OrderStatus.REVIEWED, OrderAction.CANCEL, UserRole.CUSTOMER))
                .isInstanceOf(BizException.class);
        // 完成后不能退回维修
        assertThatThrownBy(() -> OrderStateMachine.validate(OrderStatus.COMPLETED, OrderAction.REJECT_FINISH, UserRole.CUSTOMER))
                .isInstanceOf(BizException.class);
        // 待验收不能被工程师关闭（只能客户验收或退回）
        assertThatThrownBy(() -> OrderStateMachine.validate(OrderStatus.PENDING_CONFIRM, OrderAction.CLOSE_UNRESOLVED, UserRole.ENGINEER))
                .isInstanceOf(BizException.class);
    }

    // ---------- 越权 ----------

    @Test
    void wrongRole_isRejected() {
        // 客户不能抢
        assertThatThrownBy(() -> OrderStateMachine.validate(OrderStatus.PENDING, OrderAction.GRAB, UserRole.CUSTOMER))
                .isInstanceOf(BizException.class);
        // 工程师不能验收（验收归客户）
        assertThatThrownBy(() -> OrderStateMachine.validate(OrderStatus.PENDING_CONFIRM, OrderAction.CONFIRM_FINISH, UserRole.ENGINEER))
                .isInstanceOf(BizException.class);
        // 系统之外不能释放
        assertThatThrownBy(() -> OrderStateMachine.validate(OrderStatus.ACCEPTED, OrderAction.RELEASE, UserRole.ENGINEER))
                .isInstanceOf(BizException.class);
    }

    // ---------- 动作可用性 ----------

    @Test
    void availableActions_exposeEngineerFlow() {
        assertThat(OrderStateMachine.availableActions(OrderStatus.PENDING))
                .containsExactlyInAnyOrder(OrderAction.GRAB, OrderAction.ASSIGN, OrderAction.CANCEL);
        assertThat(OrderStateMachine.availableActions(OrderStatus.ACCEPTED))
                .containsExactlyInAnyOrder(OrderAction.CANCEL, OrderAction.RELEASE, OrderAction.DEPART);
        assertThat(OrderStateMachine.availableActions(OrderStatus.REVIEWED))
                .containsExactly(OrderAction.REVIEW);
    }
}
