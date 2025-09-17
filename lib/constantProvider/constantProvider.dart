import 'package:flutter/material.dart';

class ConstantProvider with ChangeNotifier {
  int _type = 500;

  int get type => _type;

  void setType(int type) {
    _type = type;
    notifyListeners();
  }
}
