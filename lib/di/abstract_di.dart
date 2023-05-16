typedef OnFinishedBind = void Function();

abstract class AbstractDI {
  void bind({OnFinishedBind? onFinishedBind});

  Future<void> unbind();
}