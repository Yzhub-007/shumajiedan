import 'package:flutter_test/flutter_test.dart';

import 'package:repairhub_app/shared/models/user_role.dart';

void main() {
  test('UserRole 解析后端角色字符串', () {
    expect(UserRole.tryParse('CUSTOMER'), UserRole.customer);
    expect(UserRole.tryParse('ENGINEER'), UserRole.engineer);
    expect(UserRole.tryParse('engineer'), UserRole.engineer);
    expect(UserRole.tryParse('ADMIN'), isNull);
    expect(UserRole.tryParse(null), isNull);
  });

  test('UserRole 与后端通信值', () {
    expect(UserRole.customer.wireValue, 'CUSTOMER');
    expect(UserRole.engineer.wireValue, 'ENGINEER');
    expect(UserRole.customer.label, '我是客户');
  });
}
