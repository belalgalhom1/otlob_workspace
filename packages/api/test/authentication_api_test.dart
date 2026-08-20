import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for AuthenticationApi
void main() {
  final instance = Api().getAuthenticationApi();

  group(AuthenticationApi, () {
    // Confirm verification code (OTP)
    //
    //Future authControllerConfirmVerification(VerifyOtpDto verifyOtpDto) async
    test('test authControllerConfirmVerification', () async {
      // TODO
    });

    // Request password reset
    //
    //Future authControllerForgotPassword(ForgotPasswordDto forgotPasswordDto) async
    test('test authControllerForgotPassword', () async {
      // TODO
    });

    // Login with email and password
    //
    //Future<AuthControllerRegister200Response> authControllerLogin(LoginDto loginDto) async
    test('test authControllerLogin', () async {
      // TODO
    });

    // Logout from current session
    //
    //Future authControllerLogout(LogoutDto logoutDto) async
    test('test authControllerLogout', () async {
      // TODO
    });

    // Logout from all sessions
    //
    //Future authControllerLogoutAll() async
    test('test authControllerLogoutAll', () async {
      // TODO
    });

    // Refresh access tokens
    //
    //Future authControllerRefreshTokens() async
    test('test authControllerRefreshTokens', () async {
      // TODO
    });

    // Register a new user
    //
    //Future<AuthControllerRegister200Response> authControllerRegister(RegisterDto registerDto) async
    test('test authControllerRegister', () async {
      // TODO
    });

    // Reset password using code
    //
    //Future authControllerResetPassword(ResetPasswordDto resetPasswordDto) async
    test('test authControllerResetPassword', () async {
      // TODO
    });

    // Request a verification code (OTP)
    //
    //Future authControllerSendVerification(SendOtpDto sendOtpDto) async
    test('test authControllerSendVerification', () async {
      // TODO
    });

  });
}
