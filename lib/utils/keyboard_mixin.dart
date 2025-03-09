import 'package:flutter/material.dart';
import 'manage_keyboard.dart';

mixin KeyboardMixin<T extends StatefulWidget> on State<T> {
  void hideKeyboard() {
    KeyboardUtils.hideKeyboard(context);
  }

  bool isKeyboardVisible() {
    return KeyboardUtils.isKeyboardVisible(context);
  }
}
