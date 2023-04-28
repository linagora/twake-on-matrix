import 'base_di.dart';

abstract class DIInterface {
  void bind({OnFinishedBind? onFinishedBind});

  Future<void> unbind();
}