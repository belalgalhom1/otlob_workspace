# api.api.UsersApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**usersControllerAdminBan**](UsersApi.md#userscontrolleradminban) | **POST** /users/{userId}/ban | [Admin] Ban a user — immediately revokes all sessions. Cannot ban SUPER_ADMIN.
[**usersControllerAdminCreate**](UsersApi.md#userscontrolleradmincreate) | **POST** /users | [Admin] Create a new user directly
[**usersControllerAdminFindAll**](UsersApi.md#userscontrolleradminfindall) | **GET** /users | [Admin] List all users — filter by role, isBanned, includeDeleted, search
[**usersControllerAdminFindOne**](UsersApi.md#userscontrolleradminfindone) | **GET** /users/{userId} | [Admin] Get a user — includes sessions, devices, vendor memberships, customer/driver snapshots
[**usersControllerAdminGetSessions**](UsersApi.md#userscontrolleradmingetsessions) | **GET** /users/{userId}/sessions | [Admin] List active sessions for a user
[**usersControllerAdminRemove**](UsersApi.md#userscontrolleradminremove) | **DELETE** /users/{userId} | [Admin] Soft-delete a user — wipes email/phone PII. Cannot delete SUPER_ADMIN.
[**usersControllerAdminRevokeAllSessions**](UsersApi.md#userscontrolleradminrevokeallsessions) | **DELETE** /users/{userId}/sessions | [Admin] Revoke all sessions for a user (force logout)
[**usersControllerAdminUnban**](UsersApi.md#userscontrolleradminunban) | **POST** /users/{userId}/unban | [Admin] Unban a user
[**usersControllerAdminUpdate**](UsersApi.md#userscontrolleradminupdate) | **PATCH** /users/{userId} | [Admin] Update a user — name, email, phone, role, title, permissions, verification flags
[**usersControllerChangePassword**](UsersApi.md#userscontrollerchangepassword) | **POST** /users/me/change-password | Change my password
[**usersControllerDeleteAccount**](UsersApi.md#userscontrollerdeleteaccount) | **DELETE** /users/me | Delete my account
[**usersControllerGetNotificationSettings**](UsersApi.md#userscontrollergetnotificationsettings) | **GET** /users/me/notification-settings | Get my notification settings
[**usersControllerGetUser**](UsersApi.md#userscontrollergetuser) | **GET** /users/me | Get my profile
[**usersControllerUpdateNotificationSettings**](UsersApi.md#userscontrollerupdatenotificationsettings) | **PATCH** /users/me/notification-settings | Update my notification settings
[**usersControllerUpdateUser**](UsersApi.md#userscontrollerupdateuser) | **PATCH** /users/me | Update my profile (name, email, phone, language)
[**usersControllerUploadAvatar**](UsersApi.md#userscontrolleruploadavatar) | **POST** /users/me/avatar | Upload my avatar


# **usersControllerAdminBan**
> ApiControllerRoot200Response usersControllerAdminBan(userId, banUserDto)

[Admin] Ban a user — immediately revokes all sessions. Cannot ban SUPER_ADMIN.

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final String userId = userId_example; // String | 
final BanUserDto banUserDto = ; // BanUserDto | 

try {
    final response = api.usersControllerAdminBan(userId, banUserDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerAdminBan: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 
 **banUserDto** | [**BanUserDto**](BanUserDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerAdminCreate**
> ApiControllerRoot200Response usersControllerAdminCreate(registerDto)

[Admin] Create a new user directly

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final RegisterDto registerDto = ; // RegisterDto | 

try {
    final response = api.usersControllerAdminCreate(registerDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerAdminCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerDto** | [**RegisterDto**](RegisterDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerAdminFindAll**
> ApiControllerRoot200Response usersControllerAdminFindAll(role, isBanned, includeDeleted, search, page, limit)

[Admin] List all users — filter by role, isBanned, includeDeleted, search

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final String role = role_example; // String | 
final bool isBanned = false; // bool | 
final bool includeDeleted = false; // bool | Include soft-deleted accounts
final String search = john; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.usersControllerAdminFindAll(role, isBanned, includeDeleted, search, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerAdminFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **role** | **String**|  | [optional] 
 **isBanned** | **bool**|  | [optional] 
 **includeDeleted** | **bool**| Include soft-deleted accounts | [optional] 
 **search** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerAdminFindOne**
> ApiControllerRoot200Response usersControllerAdminFindOne(userId)

[Admin] Get a user — includes sessions, devices, vendor memberships, customer/driver snapshots

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final String userId = userId_example; // String | 

try {
    final response = api.usersControllerAdminFindOne(userId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerAdminFindOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerAdminGetSessions**
> ApiControllerRoot200Response usersControllerAdminGetSessions(userId)

[Admin] List active sessions for a user

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final String userId = userId_example; // String | 

try {
    final response = api.usersControllerAdminGetSessions(userId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerAdminGetSessions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerAdminRemove**
> ApiControllerRoot200Response usersControllerAdminRemove(userId)

[Admin] Soft-delete a user — wipes email/phone PII. Cannot delete SUPER_ADMIN.

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final String userId = userId_example; // String | 

try {
    final response = api.usersControllerAdminRemove(userId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerAdminRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerAdminRevokeAllSessions**
> ApiControllerRoot200Response usersControllerAdminRevokeAllSessions(userId)

[Admin] Revoke all sessions for a user (force logout)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final String userId = userId_example; // String | 

try {
    final response = api.usersControllerAdminRevokeAllSessions(userId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerAdminRevokeAllSessions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerAdminUnban**
> ApiControllerRoot200Response usersControllerAdminUnban(userId)

[Admin] Unban a user

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final String userId = userId_example; // String | 

try {
    final response = api.usersControllerAdminUnban(userId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerAdminUnban: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerAdminUpdate**
> ApiControllerRoot200Response usersControllerAdminUpdate(userId, adminUpdateUserDto)

[Admin] Update a user — name, email, phone, role, title, permissions, verification flags

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final String userId = userId_example; // String | 
final AdminUpdateUserDto adminUpdateUserDto = ; // AdminUpdateUserDto | 

try {
    final response = api.usersControllerAdminUpdate(userId, adminUpdateUserDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerAdminUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 
 **adminUpdateUserDto** | [**AdminUpdateUserDto**](AdminUpdateUserDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerChangePassword**
> ApiControllerRoot200Response usersControllerChangePassword(changePasswordDto)

Change my password

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final ChangePasswordDto changePasswordDto = ; // ChangePasswordDto | 

try {
    final response = api.usersControllerChangePassword(changePasswordDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerChangePassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **changePasswordDto** | [**ChangePasswordDto**](ChangePasswordDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerDeleteAccount**
> ApiControllerRoot200Response usersControllerDeleteAccount()

Delete my account

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();

try {
    final response = api.usersControllerDeleteAccount();
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerDeleteAccount: $e\n');
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

# **usersControllerGetNotificationSettings**
> ApiControllerRoot200Response usersControllerGetNotificationSettings()

Get my notification settings

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();

try {
    final response = api.usersControllerGetNotificationSettings();
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerGetNotificationSettings: $e\n');
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

# **usersControllerGetUser**
> ApiControllerRoot200Response usersControllerGetUser()

Get my profile

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();

try {
    final response = api.usersControllerGetUser();
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerGetUser: $e\n');
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

# **usersControllerUpdateNotificationSettings**
> ApiControllerRoot200Response usersControllerUpdateNotificationSettings(updateNotificationSettingsDto)

Update my notification settings

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final UpdateNotificationSettingsDto updateNotificationSettingsDto = ; // UpdateNotificationSettingsDto | 

try {
    final response = api.usersControllerUpdateNotificationSettings(updateNotificationSettingsDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerUpdateNotificationSettings: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateNotificationSettingsDto** | [**UpdateNotificationSettingsDto**](UpdateNotificationSettingsDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerUpdateUser**
> ApiControllerRoot200Response usersControllerUpdateUser(updateUserDto)

Update my profile (name, email, phone, language)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final UpdateUserDto updateUserDto = ; // UpdateUserDto | 

try {
    final response = api.usersControllerUpdateUser(updateUserDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerUpdateUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateUserDto** | [**UpdateUserDto**](UpdateUserDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerUploadAvatar**
> ApiControllerRoot200Response usersControllerUploadAvatar(file)

Upload my avatar

### Example
```dart
import 'package:api/api.dart';

final api = Api().getUsersApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.usersControllerUploadAvatar(file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling UsersApi->usersControllerUploadAvatar: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

