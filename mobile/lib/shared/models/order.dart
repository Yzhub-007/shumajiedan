/// 工单模型（与后端 OrderResponse 对齐）。
class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.statusLabel,
    this.engineerId,
    this.engineerName,
    this.deviceCategoryName,
    this.deviceBrand,
    this.deviceModel,
    required this.faultDesc,
    this.mediaUrls = const [],
    this.addressText,
    this.urgencyLabel,
    this.quoteAmount,
    this.finalAmount,
    this.estimatedAmount,
    this.createdAt,
  });

  final int id;
  final String orderNo;
  final String status;
  final String statusLabel;
  final int? engineerId;
  final String? engineerName;
  final String? deviceCategoryName;
  final String? deviceBrand;
  final String? deviceModel;
  final String faultDesc;
  final List<String> mediaUrls;
  final String? addressText;
  final String? urgencyLabel;
  final num? quoteAmount;
  final num? finalAmount;
  final num? estimatedAmount;
  final String? createdAt;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      orderNo: json['orderNo'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['statusLabel'] as String? ?? '',
      engineerId: json['engineerId'] as int?,
      engineerName: json['engineerName'] as String?,
      deviceCategoryName: json['deviceCategoryName'] as String?,
      deviceBrand: json['deviceBrand'] as String?,
      deviceModel: json['deviceModel'] as String?,
      faultDesc: json['faultDesc'] as String? ?? '',
      mediaUrls:
          (json['mediaUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      addressText: json['addressText'] as String?,
      urgencyLabel: json['urgencyLabel'] as String?,
      quoteAmount: json['quoteAmount'] as num?,
      finalAmount: json['finalAmount'] as num?,
      estimatedAmount: json['estimatedAmount'] as num?,
      createdAt: json['createdAt'] as String?,
    );
  }

  /// 与后端 OrderStatus 枚举对应，用于端内逻辑判断与颜色映射
  OrderStatusKind get statusKind {
    switch (status) {
      case 'PENDING':
        return OrderStatusKind.pending;
      case 'ACCEPTED':
      case 'ON_THE_WAY':
      case 'ARRIVED':
        return OrderStatusKind.inProgress;
      case 'REPAIRING':
        return OrderStatusKind.repairing;
      case 'PENDING_CONFIRM':
        return OrderStatusKind.pendingConfirm;
      case 'PENDING_PAYMENT':
        return OrderStatusKind.pendingPayment;
      case 'COMPLETED':
      case 'REVIEWED':
        return OrderStatusKind.done;
      default:
        return OrderStatusKind.closed;
    }
  }
}

enum OrderStatusKind { pending, inProgress, repairing, pendingConfirm, pendingPayment, done, closed }
