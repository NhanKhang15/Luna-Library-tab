import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';
import '../models/user_model.dart';

/// Authentication service for login/signup/OTP/Google auth
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'auth_user';

  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  // ============== LOGIN ==============

  /// Login with identifier (username/email/phone) and password
  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.authBaseUrl}/auth/login');

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'identifier': identifier, 'password': password}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final loginResponse = LoginResponse.fromJson(json);
        await _saveAuth(loginResponse);
        return AuthResult.success(loginResponse);
      } else if (response.statusCode == 401) {
        return AuthResult.error('Tài khoản hoặc mật khẩu không đúng');
      } else if (response.statusCode == 403) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = json['detail'] as String? ?? '';
        if (detail.contains('not verified')) {
          return AuthResult.error(
            'Tài khoản chưa được xác thực. Vui lòng xác thực OTP.',
          );
        }
        return AuthResult.error('Tài khoản đã bị vô hiệu hóa');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.error(json['detail'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      return AuthResult.error('Không thể kết nối đến máy chủ: $e');
    }
  }

  // ============== SIGNUP ==============

  /// Register new local account
  Future<AuthResult> signup({
    required String username,
    required String password,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.authBaseUrl}/auth/signup');

      final body = {'username': username, 'password': password};
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        body['phoneNumber'] = phoneNumber;

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final signupResponse = SignupResponse.fromJson(json);
        return AuthResult.signupSuccess(signupResponse);
      } else if (response.statusCode == 409) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.error(json['detail'] ?? 'Tài khoản đã tồn tại');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.error(json['detail'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      return AuthResult.error('Không thể kết nối đến máy chủ: $e');
    }
  }

  // ============== OTP ==============

  /// Request OTP for account verification
  Future<AuthResult> requestOTP({
    required int userId,
    required String method, // 'email' or 'sms'
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.authBaseUrl}/auth/otp/request');

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userId': userId, 'method': method}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final otpResponse = OTPRequestResponse.fromJson(json);
        return AuthResult.otpRequestSuccess(otpResponse);
      } else if (response.statusCode == 429) {
        return AuthResult.error('Quá nhiều yêu cầu. Vui lòng thử lại sau.');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.error(json['detail'] ?? 'Không thể gửi OTP');
      }
    } catch (e) {
      return AuthResult.error('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Verify OTP
  Future<AuthResult> verifyOTP({
    required int userId,
    required String otp,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.authBaseUrl}/auth/otp/verify');

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userId': userId, 'otp': otp}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final verifyResponse = OTPVerifyResponse.fromJson(json);
        return AuthResult.otpVerifySuccess(verifyResponse);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.error(json['detail'] ?? 'OTP không hợp lệ');
      }
    } catch (e) {
      return AuthResult.error('Không thể kết nối đến máy chủ: $e');
    }
  }

  // ============== GOOGLE LOGIN ==============

  /// Login with Google ID token
  Future<AuthResult> googleLogin({required String idToken}) async {
    try {
      final uri = Uri.parse('${ApiConfig.authBaseUrl}/auth/google');

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final googleResponse = GoogleLoginResponse.fromJson(json);

        // Save auth tokens
        await _saveAuthFromGoogle(googleResponse);

        return AuthResult.googleLoginSuccess(googleResponse);
      } else if (response.statusCode == 401) {
        return AuthResult.error('Token Google không hợp lệ');
      } else if (response.statusCode == 409) {
        return AuthResult.error('Email đã được đăng ký với tài khoản khác');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.error(json['detail'] ?? 'Đăng nhập Google thất bại');
      }
    } catch (e) {
      return AuthResult.error('Không thể kết nối đến máy chủ: $e');
    }
  }

  // ============== FACEBOOK LOGIN ==============

  /// Login with Facebook access token
  Future<AuthResult> facebookLogin({required String accessToken}) async {
    try {
      final uri = Uri.parse('${ApiConfig.authBaseUrl}/auth/facebook');

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'accessToken': accessToken}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final facebookResponse = FacebookLoginResponse.fromJson(json);

        // Save auth tokens
        await _saveAuthFromFacebook(facebookResponse);

        return AuthResult.facebookLoginSuccess(facebookResponse);
      } else if (response.statusCode == 401) {
        return AuthResult.error('Token Facebook không hợp lệ');
      } else if (response.statusCode == 409) {
        return AuthResult.error('Email đã được đăng ký với tài khoản khác');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.error(
          json['detail'] ?? 'Đăng nhập Facebook thất bại',
        );
      }
    } catch (e) {
      return AuthResult.error('Không thể kết nối đến máy chủ: $e');
    }
  }

  // ============== TOKEN MANAGEMENT ==============

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;

    try {
      final json = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  Future<void> _saveAuth(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.accessToken);
    await prefs.setString(_refreshTokenKey, response.refreshToken);
    await prefs.setString(_userKey, jsonEncode(response.user.toJson()));
  }

  Future<void> _saveAuthFromGoogle(GoogleLoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.accessToken);
    await prefs.setString(_refreshTokenKey, response.refreshToken);
    await prefs.setString(_userKey, jsonEncode(response.user.toJson()));
  }

  Future<void> _saveAuthFromFacebook(FacebookLoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.accessToken);
    await prefs.setString(_refreshTokenKey, response.refreshToken);
    await prefs.setString(_userKey, jsonEncode(response.user.toJson()));
  }

  void dispose() {
    _client.close();
  }
}

/// Result of auth operations
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final LoginResponse? loginResponse;
  final SignupResponse? signupResponse;
  final OTPRequestResponse? otpRequestResponse;
  final OTPVerifyResponse? otpVerifyResponse;
  final GoogleLoginResponse? googleLoginResponse;
  final FacebookLoginResponse? facebookLoginResponse;

  AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.loginResponse,
    this.signupResponse,
    this.otpRequestResponse,
    this.otpVerifyResponse,
    this.googleLoginResponse,
    this.facebookLoginResponse,
  });

  factory AuthResult.success(LoginResponse response) {
    return AuthResult._(isSuccess: true, loginResponse: response);
  }

  factory AuthResult.signupSuccess(SignupResponse response) {
    return AuthResult._(isSuccess: true, signupResponse: response);
  }

  factory AuthResult.otpRequestSuccess(OTPRequestResponse response) {
    return AuthResult._(isSuccess: true, otpRequestResponse: response);
  }

  factory AuthResult.otpVerifySuccess(OTPVerifyResponse response) {
    return AuthResult._(isSuccess: true, otpVerifyResponse: response);
  }

  factory AuthResult.googleLoginSuccess(GoogleLoginResponse response) {
    return AuthResult._(isSuccess: true, googleLoginResponse: response);
  }

  factory AuthResult.facebookLoginSuccess(FacebookLoginResponse response) {
    return AuthResult._(isSuccess: true, facebookLoginResponse: response);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}
