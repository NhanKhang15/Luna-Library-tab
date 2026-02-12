import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../login/login_screen.dart';
import '../otp/otp_verification_screen.dart';
import '../../screens/library_screen.dart';
import '../../services/auth_service.dart';
import '../../core/app_colors.dart';
import '../../core/responsive_utils.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _scrollController = ScrollController();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptTerms = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với Điều khoản sử dụng'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.signup(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      phoneNumber: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.signupResponse?.message ?? 'Đăng ký thành công!',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate to OTP verification after successful signup
      if (result.signupResponse != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              userId: result.signupResponse!.userId,
              email: _emailController.text.trim().isNotEmpty
                  ? _emailController.text.trim()
                  : null,
              phone: _phoneController.text.trim().isNotEmpty
                  ? _phoneController.text.trim()
                  : null,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Đăng ký thất bại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Handle Google Sign-In flow
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lấy token từ Google'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final result = await _authService.googleLogin(idToken: idToken);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chào mừng ${result.googleLoginResponse!.user.displayName}!',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LibraryScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Đăng nhập Google thất bại'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng nhập Google: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Handle Facebook Sign-In flow
  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);

    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        setState(() => _isLoading = false);
        return;
      }

      if (result.status != LoginStatus.success) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập Facebook thất bại: ${result.message}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lấy token từ Facebook'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Call backend API
      final authResult = await _authService.facebookLogin(
        accessToken: accessToken.tokenString,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (authResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chào mừng ${authResult.facebookLoginResponse!.user.displayName}!',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LibraryScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authResult.errorMessage ?? 'Đăng nhập Facebook thất bại',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng nhập Facebook: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = ResponsiveUtils.screenHeight(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);
    final isSmallScreen = screenHeight < 700;
    final isTablet = ResponsiveUtils.isTablet(context);

    // Responsive spacing
    final topSpacing = isLandscape ? 12.0 : (isSmallScreen ? 16.0 : 28.0);
    final logoSize = isSmallScreen ? 60.0 : 70.0;
    final cardPadding = isSmallScreen ? 18.0 : 22.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDEFF4),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top spacing
                      SizedBox(height: topSpacing),

                      // Logo section (smaller for signup)
                      _buildLogoSection(logoSize, isSmallScreen),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Signup Card - responsive width
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.horizontalPadding(context),
                        ),
                        child: ResponsiveMaxWidthContainer(
                          maxWidthOverride: isTablet ? 440 : null,
                          child: _buildSignupCard(cardPadding, isSmallScreen),
                        ),
                      ),

                      // Footer
                      SizedBox(height: isSmallScreen ? 12 : 20),
                      _buildFooter(),
                      SizedBox(height: isSmallScreen ? 8 : 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoSection(double logoSize, bool isSmallScreen) {
    final iconSize = logoSize * 0.5;
    final titleSize = isSmallScreen ? 22.0 : 26.0;
    final subtitleSize = isSmallScreen ? 11.0 : 13.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(logoSize * 0.25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B9D).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.spa_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
          ).createShader(bounds),
          child: Text(
            'FLORIA',
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Ứng dụng chăm sóc sức khỏe phụ nữ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: subtitleSize,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupCard(double padding, bool isSmallScreen) {
    final titleSize = isSmallScreen ? 20.0 : 22.0;
    final subtitleSize = isSmallScreen ? 12.0 : 13.0;
    final fieldSpacing = isSmallScreen ? 12.0 : 16.0;
    final buttonHeight = ResponsiveUtils.buttonHeight(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Đăng Ký',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              'Tạo tài khoản để bắt đầu hành trình của bạn',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: subtitleSize,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 18 : 24),

            // Username field
            _buildLabel('Tên đăng nhập (*)'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _usernameController,
              hintText: 'Nhập tên đăng nhập',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Vui lòng nhập tên đăng nhập'
                  : null,
            ),
            SizedBox(height: fieldSpacing),

            // Email field
            _buildLabel('Email (tùy chọn - dùng cho OTP)'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _emailController,
              hintText: 'Nhập địa chỉ email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v != null && v.isNotEmpty && !v.contains('@')) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            SizedBox(height: fieldSpacing),

            // Phone field
            _buildLabel('Số điện thoại (tùy chọn - dùng cho OTP)'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _phoneController,
              hintText: 'Nhập số điện thoại',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: fieldSpacing),

            // Password field
            _buildLabel('Mật khẩu (*)'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _passwordController,
              hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signup(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            SizedBox(height: fieldSpacing),

            // Info box
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B9D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF6B9D),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn cần xác thực tài khoản qua OTP sau khi đăng ký. Vui lòng nhập email hoặc số điện thoại.',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: const Color(0xFF666666),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 14 : 18),

            // Terms checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _acceptTerms,
                    onChanged: (v) =>
                        setState(() => _acceptTerms = v ?? false),
                    activeColor: const Color(0xFFFF6B9D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isSmallScreen ? 11 : 12,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Tôi đồng ý với '),
                        TextSpan(
                          text: 'Điều khoản sử dụng',
                          style: const TextStyle(
                            color: Color(0xFFFF6B9D),
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                        const TextSpan(text: ' và '),
                        TextSpan(
                          text: 'Chính sách bảo mật',
                          style: const TextStyle(
                            color: Color(0xFFFF6B9D),
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 18 : 22),

            // Signup button
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B9D).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Đăng Ký',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 18 : 22),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Hoặc tiếp tục với',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),

            SizedBox(height: isSmallScreen ? 14 : 16),

            // Social buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIconButton(
                  icon: FontAwesomeIcons.facebookF,
                  onPressed: _handleFacebookSignIn,
                ),
                const SizedBox(width: 20),
                _buildSocialIconButton(
                  icon: FontAwesomeIcons.apple,
                  onPressed: () {
                    // TODO: Apple login
                  },
                ),
                const SizedBox(width: 20),
                _buildSocialIconButton(
                  icon: FontAwesomeIcons.google,
                  onPressed: _handleGoogleSignIn,
                ),
              ],
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Đã có tài khoản? ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      color: Color(0xFFFF6B9D),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      '© 2025 Floria. Tất cả quyền được bảo lưu.',
      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[400], size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
        errorMaxLines: 2,
        isDense: true,
      ),
    );
  }

  Widget _buildSocialIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(icon, size: 16, color: Colors.grey[800]),
        ),
      ),
    );
  }
}
