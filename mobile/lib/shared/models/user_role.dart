/// 用户身份：客户端 / 工程师端（同一 App 两种身份，计划书 2.1）。
enum UserRole {
  customer,
  engineer;

  String get label => this == UserRole.customer ? '我是客户' : '我是工程师';

  /// 后端角色字符串：CUSTOMER / ENGINEER
  String get wireValue => name.toUpperCase();

  static UserRole? tryParse(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'CUSTOMER':
        return UserRole.customer;
      case 'ENGINEER':
        return UserRole.engineer;
      default:
        return null;
    }
  }
}
