import 'package:flutter/material.dart';

class SelectionManager extends ChangeNotifier {
  static final SelectionManager instance = SelectionManager._internal();

  SelectionManager._internal();

  final Set<String> _selectedIds = {};

  Set<String> get selectedIds => _selectedIds;

  bool isSelected(String id) => _selectedIds.contains(id);

  void toggle(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clear() {
    _selectedIds.clear();
    notifyListeners();
  }

  bool get hasSelection => _selectedIds.isNotEmpty;
}