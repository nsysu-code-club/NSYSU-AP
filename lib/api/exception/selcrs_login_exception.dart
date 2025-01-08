sealed class SelcrsLoginException {}

/// 選課系統密碼錯誤
class SelcrsLoginCoursePasswordException extends SelcrsLoginException {}

/// 成績系統密碼錯誤
class SelcrsLoginScorePasswordException extends SelcrsLoginException {}

/// 選課系統需填寫防疫表單
class SelcrsLoginConfirmFormException extends SelcrsLoginException {}

/// 未知錯誤
class SelcrsLoginUnknownException extends SelcrsLoginException {}
