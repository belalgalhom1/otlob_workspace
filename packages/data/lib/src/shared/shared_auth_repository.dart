import 'package:api/api.dart';
import 'package:core/core.dart';
import '../shared/response_parser.dart';

/// Fallback error key used only when the server returned a 2xx response that
/// is missing the expected auth payload. Real auth failures (401/403/etc.)
/// surface as [DioException] from the generated API client and propagate
/// untouched so the backend's own error key reaches the UI.
const _missingAuthPayloadKey = 'auth.error.invalid_credentials';

class SharedAuthRepository {
  final AuthenticationApi _api;
  final TokenService _tokenService;
  
  SharedAuthRepository(this._api, this._tokenService);

  Future<dynamic> register(RegisterDto registerDto) async {
    final response = await _api.authControllerRegister(
      registerDto: registerDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> refreshTokens() async {
    final response = await _api.authControllerRefreshTokens();
    return ResponseParser.parse(response);
  }

  Future<dynamic> logoutAll() async {
    try {
      final response = await _api.authControllerLogoutAll();
      await _tokenService.clearSession();
      return ResponseParser.parse(response);
    } catch (_) {
      await _tokenService.clearSession();
      rethrow;
    }
  }

  Future<dynamic> forgotPassword(String contact) async {
    final response = await _api.authControllerForgotPassword(
      forgotPasswordDto: ForgotPasswordDto((b) => b..contact = contact)
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> resetPassword(String contact, String code, String newPassword) async {
    final response = await _api.authControllerResetPassword(
      resetPasswordDto: ResetPasswordDto((b) => b
        ..contact = contact
        ..code = code
        ..newPassword = newPassword
      )
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> sendVerification(String contact, String method) async {
    final response = await _api.authControllerSendVerification(
      sendOtpDto: SendOtpDto((b) => b
        ..contact = contact
        ..method = SendOtpDtoMethodEnum.valueOf(method.toUpperCase())
      )
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> confirmVerification(String contact, String code, {String? purpose}) async {
    final response = await _api.authControllerConfirmVerification(
      verifyOtpDto: VerifyOtpDto((b) => b
        ..contact = contact
        ..code = code
        ..purpose = purpose != null ? VerifyOtpDtoPurposeEnum.valueOf(purpose.toUpperCase()) : null
      )
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> login(String email, String password, {String? appType}) async {
    final response = await _api.authControllerLogin(
      loginDto: LoginDto((b) {
        b.email = email;
        b.password = password;
        if (appType != null) {
          b.app = appType;
        }
      })
    );
    final rawData = response.data;
    if (rawData == null) {
      throw Exception(_missingAuthPayloadKey);
    }

    Map<String, dynamic> payload = {};
    if (rawData.data != null && rawData.data!.value is Map) {
      payload = Map<String, dynamic>.from(rawData.data!.value as Map);
    } else {
      // Fallback to parsed if JsonObject is not a Map
      final parsed = ResponseParser.parse(response);
      payload = (parsed is Map && parsed.containsKey('data') && parsed['data'] != null) ? parsed['data'] : (parsed is Map ? parsed : {});
    }
    
    if (payload.isNotEmpty && payload['access_token'] != null) {
      final user = payload['user'];
      List<dynamic> vendorMemberships = [];
      List<dynamic> permissions = [];

      if (user != null && user['vendorMemberships'] != null) {
        vendorMemberships = user['vendorMemberships'] as List<dynamic>;
      }

      if (user != null && user['permissions'] != null) {
        permissions = user['permissions'] as List<dynamic>;
      }

      await _tokenService.saveSession(
        accessToken: payload['access_token'],
        refreshToken: payload['refresh_token'],
        userId: user?['id'],
        role: user?['role'],
        name: user?['name'],
        vendorMemberships: vendorMemberships,
        permissions: permissions,
      );
      
      // Store memberships in the parsed object so the UI can use it
      payload['vendorMemberships'] = vendorMemberships;
      payload['permissions'] = permissions;
      return payload;
    }
    
    throw Exception(_missingAuthPayloadKey);
  }

  Future<dynamic> socialLogin(SocialLoginDto socialLoginDto) async {
    final response = await _api.authControllerSocialLogin(
      socialLoginDto: socialLoginDto,
    );
    final rawData = response.data;
    if (rawData == null) {
      throw Exception(_missingAuthPayloadKey);
    }

    Map<String, dynamic> payload = {};
    if (rawData.data != null && rawData.data!.value is Map) {
      payload = Map<String, dynamic>.from(rawData.data!.value as Map);
    } else {
      final parsed = ResponseParser.parse(response);
      payload = (parsed is Map && parsed.containsKey('data') && parsed['data'] != null)
          ? parsed['data']
          : (parsed is Map ? parsed : {});
    }

    if (payload.isNotEmpty && payload['access_token'] != null) {
      final user = payload['user'];
      List<dynamic> vendorMemberships = [];
      List<dynamic> permissions = [];

      if (user != null && user['vendorMemberships'] != null) {
        vendorMemberships = user['vendorMemberships'] as List<dynamic>;
      }

      if (user != null && user['permissions'] != null) {
        permissions = user['permissions'] as List<dynamic>;
      }

      await _tokenService.saveSession(
        accessToken: payload['access_token'],
        refreshToken: payload['refresh_token'],
        userId: user?['id'],
        role: user?['role'],
        name: user?['name'],
        vendorMemberships: vendorMemberships,
        permissions: permissions,
      );

      payload['vendorMemberships'] = vendorMemberships;
      payload['permissions'] = permissions;
      return payload;
    }

    throw Exception(_missingAuthPayloadKey);
  }

  Future<void> logout({String? fcmToken}) async {
    // Skip the network call when there is no session to revoke. Calling it
    // without a bearer token just 401s, and in combination with the auth
    // interceptor's stream event can turn into a logout feedback loop.
    final hasToken = await _tokenService.hasSession();
    if (hasToken) {
      try {
        await _api.authControllerLogout(
          logoutDto: LogoutDto((b) {
            if (fcmToken != null) b.fcmToken = fcmToken;
          }),
        );
      } catch (_) {}
    }
    await _tokenService.clearSession();
  }

  Future<String?> getUserId() => _tokenService.getUserId();
  Future<String?> getUserRole() => _tokenService.getUserRole();
  Future<String?> getUserName() => _tokenService.getUserName();
  Future<bool> isLoggedIn() => _tokenService.hasSession();
  Future<bool> isTokenExpired() => _tokenService.isTokenExpired();
  Future<String> refreshToken() => _tokenService.refreshToken();

  Future<List<dynamic>> getVendorMemberships() async {
    return _tokenService.getVendorMemberships();
  }

  Future<List<String>> getUserPermissions() async {
    return _tokenService.getUserPermissions();
  }
}
