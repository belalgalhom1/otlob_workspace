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
[**authControllerLinkSocialAccount**](AuthenticationApi.md#authcontrollerlinksocialaccount) | **POST** /auth/social/link | Link a Google/Apple account to the current user
[**authControllerLogin**](AuthenticationApi.md#authcontrollerlogin) | **POST** /auth/login | Login with email and password
[**authControllerLogout**](AuthenticationApi.md#authcontrollerlogout) | **POST** /auth/logout | Logout from current session
[**authControllerLogoutAll**](AuthenticationApi.md#authcontrollerlogoutall) | **POST** /auth/logout-all | Logout from all sessions
[**authControllerRefreshTokens**](AuthenticationApi.md#authcontrollerrefreshtokens) | **POST** /auth/refresh | Refresh access tokens
[**authControllerRegister**](AuthenticationApi.md#authcontrollerregister) | **POST** /auth/register | Register a new user
[**authControllerResetPassword**](AuthenticationApi.md#authcontrollerresetpassword) | **POST** /auth/password/reset | Reset password using code
[**authControllerSendVerification**](AuthenticationApi.md#authcontrollersendverification) | **POST** /auth/verify/request | Request a verification code (OTP)
[**authControllerSocialLogin**](AuthenticationApi.md#authcontrollersociallogin) | **POST** /auth/social | Login with OAuth provider (Google/Apple)
[**authControllerUnlinkSocialAccount**](AuthenticationApi.md#authcontrollerunlinksocialaccount) | **DELETE** /auth/social/unlink/{provider} | Unlink a Google/Apple account from the current user


# **authControllerConfirmVerification**
> ApiControllerRoot200Response authControllerConfirmVerification(verifyOtpDto)

Confirm verification code (OTP)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final VerifyOtpDto verifyOtpDto = ; // VerifyOtpDto | 

try {
    final response = api.authControllerConfirmVerification(verifyOtpDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerConfirmVerification: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **verifyOtpDto** | [**VerifyOtpDto**](VerifyOtpDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerForgotPassword**
> ApiControllerRoot200Response authControllerForgotPassword(forgotPasswordDto)

Request password reset

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final ForgotPasswordDto forgotPasswordDto = ; // ForgotPasswordDto | 

try {
    final response = api.authControllerForgotPassword(forgotPasswordDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerForgotPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **forgotPasswordDto** | [**ForgotPasswordDto**](ForgotPasswordDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerLinkSocialAccount**
> ApiControllerRoot200Response authControllerLinkSocialAccount(socialLoginDto)

Link a Google/Apple account to the current user

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final SocialLoginDto socialLoginDto = ; // SocialLoginDto | 

try {
    final response = api.authControllerLinkSocialAccount(socialLoginDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerLinkSocialAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **socialLoginDto** | [**SocialLoginDto**](SocialLoginDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerLogin**
> ApiControllerRoot200Response authControllerLogin(loginDto)

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

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerLogout**
> ApiControllerRoot200Response authControllerLogout(logoutDto)

Logout from current session

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final LogoutDto logoutDto = ; // LogoutDto | 

try {
    final response = api.authControllerLogout(logoutDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerLogout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **logoutDto** | [**LogoutDto**](LogoutDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerLogoutAll**
> ApiControllerRoot200Response authControllerLogoutAll()

Logout from all sessions

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();

try {
    final response = api.authControllerLogoutAll();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerLogoutAll: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerRefreshTokens**
> ApiControllerRoot200Response authControllerRefreshTokens()

Refresh access tokens

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();

try {
    final response = api.authControllerRefreshTokens();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerRefreshTokens: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerRegister**
> ApiControllerRoot200Response authControllerRegister(registerDto)

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

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerResetPassword**
> ApiControllerRoot200Response authControllerResetPassword(resetPasswordDto)

Reset password using code

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final ResetPasswordDto resetPasswordDto = ; // ResetPasswordDto | 

try {
    final response = api.authControllerResetPassword(resetPasswordDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerResetPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resetPasswordDto** | [**ResetPasswordDto**](ResetPasswordDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerSendVerification**
> ApiControllerRoot200Response authControllerSendVerification(sendOtpDto)

Request a verification code (OTP)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final SendOtpDto sendOtpDto = ; // SendOtpDto | 

try {
    final response = api.authControllerSendVerification(sendOtpDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerSendVerification: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sendOtpDto** | [**SendOtpDto**](SendOtpDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerSocialLogin**
> ApiControllerRoot200Response authControllerSocialLogin(socialLoginDto)

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

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerUnlinkSocialAccount**
> ApiControllerRoot200Response authControllerUnlinkSocialAccount(provider)

Unlink a Google/Apple account from the current user

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuthenticationApi();
final String provider = provider_example; // String | 

try {
    final response = api.authControllerUnlinkSocialAccount(provider);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthenticationApi->authControllerUnlinkSocialAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **provider** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

