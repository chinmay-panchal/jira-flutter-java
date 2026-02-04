class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';

  static const String authLogin = '/auth/login';
  static const String authSignup = '/auth/signup';
  static const String authSendOtp = '/auth/otp/send';
  static const String authVerifyOtp = '/auth/otp/verify';
  static const String authResetPassword = '/auth/password/reset';

  static const String users = '/users';
  static const String userSearch = '/users/search';

  static const String projects = '/projects';
  static const String tasks = '/tasks';
}
