import 'package:collection/collection.dart';

enum AdminUsers { admin1, admin2, admin3, admin4, admin5 }

extension AdminUserExt on AdminUsers {
  String get id => name;

  static AdminUsers? fromId(String id) {
    return AdminUsers.values.firstWhereOrNull((admin) => admin.id == id);
  }
}
