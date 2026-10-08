import 'package:flutter/widgets.dart';

/// Metin giriş bileşenlerinin ortak controller/focus node yönetimi: dışarıdan verilen
/// varsa onu kullanır (dispose etmez), yoksa kendisi yaratır ve temizler; ikisini de
/// dinleyip bileşeni yeniden çizer.
mixin TextInputControllersMixin<T extends StatefulWidget> on State<T> {
  /// `widget.controller` / `widget.focusNode`.
  TextEditingController? get externalController;
  FocusNode? get externalFocusNode;

  late TextEditingController controller;
  late FocusNode focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  bool get hasFocus => focusNode.hasFocus;
  bool get hasText => controller.text.isNotEmpty;

  /// `initState` içinde, `super.initState()`'ten sonra çağrılır.
  void initControllers() {
    _attachController();
    _attachFocusNode();
  }

  /// `didUpdateWidget` içinde, eski widget'ın değerleriyle çağrılır.
  void didUpdateControllers(
    TextEditingController? oldController,
    FocusNode? oldFocusNode,
  ) {
    if (oldController != externalController) {
      _detachController();
      _attachController();
    }
    if (oldFocusNode != externalFocusNode) {
      _detachFocusNode();
      _attachFocusNode();
    }
  }

  /// `dispose` içinde, `super.dispose()`'tan önce çağrılır.
  void disposeControllers() {
    _detachController();
    _detachFocusNode();
  }

  void _attachController() {
    _ownsController = externalController == null;
    controller = externalController ?? TextEditingController();
    controller.addListener(_rebuild);
  }

  void _attachFocusNode() {
    _ownsFocusNode = externalFocusNode == null;
    focusNode = externalFocusNode ?? FocusNode();
    focusNode.addListener(_rebuild);
  }

  void _detachController() {
    controller.removeListener(_rebuild);
    if (_ownsController) controller.dispose();
  }

  void _detachFocusNode() {
    focusNode.removeListener(_rebuild);
    if (_ownsFocusNode) focusNode.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }
}
