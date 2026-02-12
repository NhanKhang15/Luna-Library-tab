/// User model for authentication - Updated for new API schema

class UserModel {
  final int id;
  final String username;
  final String? email;
  final String? phoneNumber;
  final String authPrimary;
  final String status;
  final bool profileCompleted;
  final bool accountVerified;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.phoneNumber,
    required this.authPrimary,
    required this.status,
    required this.profileCompleted,
    required this.accountVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      authPrimary: json['authPrimary'] as String? ?? 'local',
      status: json['status'] as String? ?? 'active',
      profileCompleted: json['profileCompleted'] as bool? ?? false,
      accountVerified: json['accountVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'authPrimary': authPrimary,
      'status': status,
      'profileCompleted': profileCompleted,
      'accountVerified': accountVerified,
    };
  }

  bool get isActive => status == 'active';
  bool get isLocalAuth => authPrimary == 'local';
  bool get isSocialAuth =>
      ['google', 'facebook', 'Apple'].contains(authPrimary);

  /// Display name (username or email)
  String get displayName => username;
}

/// Login response from API
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Signup response from API (account created, needs OTP verification)
class SignupResponse {
  final bool success;
  final int userId;
  final String message;

  SignupResponse({
    required this.success,
    required this.userId,
    required this.message,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      success: json['success'] as bool,
      userId: json['userId'] as int,
      message: json['message'] as String,
    );
  }
}

/// OTP request response
class OTPRequestResponse {
  final bool success;
  final String message;

  OTPRequestResponse({required this.success, required this.message});

  factory OTPRequestResponse.fromJson(Map<String, dynamic> json) {
    return OTPRequestResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
}

/// OTP verify response
class OTPVerifyResponse {
  final bool success;
  final bool accountVerified;
  final String message;

  OTPVerifyResponse({
    required this.success,
    required this.accountVerified,
    required this.message,
  });

  factory OTPVerifyResponse.fromJson(Map<String, dynamic> json) {
    return OTPVerifyResponse(
      success: json['success'] as bool,
      accountVerified: json['accountVerified'] as bool,
      message: json['message'] as String,
    );
  }
}

/// Google login response
class GoogleLoginResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel user;
  final bool isNewUser;

  GoogleLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
    required this.isNewUser,
  });

  factory GoogleLoginResponse.fromJson(Map<String, dynamic> json) {
    return GoogleLoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      isNewUser: json['isNewUser'] as bool,
    );
  }
}

/// Facebook login response
class FacebookLoginResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel user;
  final bool isNewUser;

  FacebookLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
    required this.isNewUser,
  });

  factory FacebookLoginResponse.fromJson(Map<String, dynamic> json) {
    return FacebookLoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      isNewUser: json['isNewUser'] as bool,
    );
  }
}
