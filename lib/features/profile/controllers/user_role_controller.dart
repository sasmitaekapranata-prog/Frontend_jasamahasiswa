import 'package:flutter/foundation.dart';

enum UserRole { pembeli, penjual }

class UserRoleController extends ChangeNotifier {
  UserRoleController._();

  static final UserRoleController instance = UserRoleController._();

  UserRole _selectedRole = UserRole.pembeli;

  UserRole get selectedRole => _selectedRole;

  void setRole(UserRole role) {
    if (_selectedRole == role) {
      return;
    }

    _selectedRole = role;
    notifyListeners();
  }
}
