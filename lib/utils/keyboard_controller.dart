import 'package:flutter/services.dart';

class KeyboardController {
  static void handleKeyPress(
    RawKeyEvent event,
    Function() onUp,
    Function() onDown,
    Function() onLeft,
    Function() onRight,
    Function()? onEnter,
  ) {
    if (event is RawKeyDownEvent) {
      switch (event.logicalKey.keyLabel) {
        case 'Arrow Up':
          onUp();
          break;
        case 'Arrow Down':
          onDown();
          break;
        case 'Arrow Left':
          onLeft();
          break;
        case 'Arrow Right':
          onRight();
          break;
        case 'Enter':
          if (onEnter != null) onEnter();
          break;
      }
    }
  }
}
