sealed class GraduationLoginException {}

/// 密碼錯誤
class GraduationLoginPasswordException extends GraduationLoginException {}

/// 未知錯誤
class GraduationLoginUnknownException extends GraduationLoginException {}
