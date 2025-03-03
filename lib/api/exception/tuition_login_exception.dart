sealed class TuitionLoginException {}

/// 密碼錯誤
class TuitionLoginPasswordException extends TuitionLoginException {}

/// 未知錯誤
class TuitionLoginUnknownException extends TuitionLoginException {}
