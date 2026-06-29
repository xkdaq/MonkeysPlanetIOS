/// 认证事件总线：解耦 HTTP 拦截器与 AuthProvider，避免循环依赖
class AuthEvent {
  static void Function()? _onExpired;

  static void onExpired(void Function() callback) => _onExpired = callback;

  static void notifyExpired() => _onExpired?.call();
}
