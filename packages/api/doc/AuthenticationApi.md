# api.api.AuthenticationApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authControllerConfirmVerification**](AuthenticationApi.md#authcontrollerconfirmverification) | **POST** /auth/verify/confirm | Confirm verification code (OTP)
[**authControllerForgotPassword**](AuthenticationApi.md#authcontrollerforgotpassword) | **POST** /auth/password/forgot | Request password reset
[**authControllerLogin**](AuthenticationApi.md#authcontrollerlogin) | **POST** /auth/login | Login with email and password
[**authControllerLogout**](AuthenticationApi.md#authcontrollerlogout) | **POST** /auth/logout | Logout from current session
[**authControllerLogoutAll**](AuthenticationApi.md#authcontrollerlogoutall) | **POST** /auth/logout-all | Logout from all sessions
[**authControllerRefreshTokens**](AuthenticationApi.md#authcontrollerrefreshtokens) | **POST** /auth/refresh | Refresh access tokens
[**authControllerRegister**](AuthenticationApi.md#authcontrollerregister) | **POST** /auth/register | Register a new user
[**authControllerResetPassword**](AuthenticationApi.md#authcontrollerresetpassword) | **POST** /auth/password/reset | Reset password using code
[**authControllerSendVerification**](AuthenticationApi.md#authcontrollersendverification) | **POST** /auth/verify/request | Request a verification code (OTP)
[**authControllerSocialLogin**](AuthenticationApi.md#authcontrollersociallogin) | **POST** /auth/social | Login with OAuth provider (Google/Apple)


# **authControllerConfirmVerification**
> authControllerConfirmVerification(verifyOtpDto)

Confirm verification code (OTP)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final VerifyOtpDto verifyOtpDto = ; // VerifyOtpDto | 

try {
    api.authControllerConfirmVerification(verifyOtpDto);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerConfirmVerification: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **verifyOtpDto** | [**VerifyOtpDto**](VerifyOtpDto.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerForgotPassword**
> authControllerForgotPassword(forgotPasswordDto)

Request password reset

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final ForgotPasswordDto forgotPasswordDto = ; // ForgotPasswordDto | 

try {
    api.authControllerForgotPassword(forgotPasswordDto);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerForgotPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **forgotPasswordDto** | [**ForgotPasswordDto**](ForgotPasswordDto.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerLogin**
> AuthControllerRegister200Response authControllerLogin(loginDto)

Login with email and password

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final LoginDto loginDto = ; // LoginDto | 

try {
    final response = api.authControllerLogin(loginDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginDto** | [**LoginDto**](LoginDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerLogout**
> authControllerLogout(logoutDto)

Logout from current session

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final LogoutDto logoutDto = ; // LogoutDto | 

try {
    api.authControllerLogout(logoutDto);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerLogout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **logoutDto** | [**LogoutDto**](LogoutDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerLogoutAll**
> authControllerLogoutAll()

Logout from all sessions

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();

try {
    api.authControllerLogoutAll();
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerLogoutAll: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerRefreshTokens**
> authControllerRefreshTokens()

Refresh access tokens

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();

try {
    api.authControllerRefreshTokens();
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerRefreshTokens: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerRegister**
> AuthControllerRegister200Response authControllerRegister(registerDto)

Register a new user

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final RegisterDto registerDto = ; // RegisterDto | 

try {
    final response = api.authControllerRegister(registerDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerRegister: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerDto** | [**RegisterDto**](RegisterDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerResetPassword**
> authControllerResetPassword(resetPasswordDto)

Reset password using code

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final ResetPasswordDto resetPasswordDto = ; // ResetPasswordDto | 

try {
    api.authControllerResetPassword(resetPasswordDto);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerResetPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resetPasswordDto** | [**ResetPasswordDto**](ResetPasswordDto.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerSendVerification**
> authControllerSendVerification(sendOtpDto)

Request a verification code (OTP)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final SendOtpDto sendOtpDto = ; // SendOtpDto | 

try {
    api.authControllerSendVerification(sendOtpDto);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerSendVerification: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sendOtpDto** | [**SendOtpDto**](SendOtpDto.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerSocialLogin**
> AuthControllerRegister200Response authControllerSocialLogin(socialLoginDto)

Login with OAuth provider (Google/Apple)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final SocialLoginDto socialLoginDto = ; // SocialLoginDto | 

try {
    final response = api.authControllerSocialLogin(socialLoginDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerSocialLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **socialLoginDto** | [**SocialLoginDto**](SocialLoginDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

