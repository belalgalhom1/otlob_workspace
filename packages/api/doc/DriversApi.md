# api.api.DriversApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**driversControllerAdminApproveBreak**](DriversApi.md#driverscontrolleradminapprovebreak) | **POST** /drivers/breaks/{breakId}/approve | [Admin] Approve a break request (driver ON_BREAK)
[**driversControllerAdminCreate**](DriversApi.md#driverscontrolleradmincreate) | **POST** /drivers/admin | [Admin] Create a new driver directly
[**driversControllerAdminCreateShift**](DriversApi.md#driverscontrolleradmincreateshift) | **POST** /drivers/{driverId}/shifts | [Admin] Create a shift for a driver
[**driversControllerAdminEndBreak**](DriversApi.md#driverscontrolleradminendbreak) | **POST** /drivers/breaks/{breakId}/end | [Admin] Force-end an active break early
[**driversControllerAdminFindAll**](DriversApi.md#driverscontrolleradminfindall) | **GET** /drivers | [Admin] List all drivers
[**driversControllerAdminFindOne**](DriversApi.md#driverscontrolleradminfindone) | **GET** /drivers/{driverId} | [Admin] Get a driver by ID
[**driversControllerAdminGetBreaks**](DriversApi.md#driverscontrolleradmingetbreaks) | **GET** /drivers/{driverId}/breaks | [Admin] List recent breaks for a driver
[**driversControllerAdminGetDriverLocation**](DriversApi.md#driverscontrolleradmingetdriverlocation) | **GET** /drivers/{driverId}/location | [Admin] Get a driver current location
[**driversControllerAdminGetPendingBreaks**](DriversApi.md#driverscontrolleradmingetpendingbreaks) | **GET** /drivers/breaks/pending | [Admin] List pending break requests
[**driversControllerAdminGetShifts**](DriversApi.md#driverscontrolleradmingetshifts) | **GET** /drivers/{driverId}/shifts | [Admin] Get shifts for a driver
[**driversControllerAdminGrantBreak**](DriversApi.md#driverscontrolleradmingrantbreak) | **POST** /drivers/{driverId}/breaks/grant | [Admin] Grant a break manually (no request needed, quota bypassed)
[**driversControllerAdminRejectBreak**](DriversApi.md#driverscontrolleradminrejectbreak) | **POST** /drivers/breaks/{breakId}/reject | [Admin] Reject a break request
[**driversControllerAdminSuspend**](DriversApi.md#driverscontrolleradminsuspend) | **POST** /drivers/{driverId}/suspend | [Admin] Suspend a driver
[**driversControllerAdminUnsuspend**](DriversApi.md#driverscontrolleradminunsuspend) | **POST** /drivers/{driverId}/unsuspend | [Admin] Unsuspend a driver
[**driversControllerAdminUpdate**](DriversApi.md#driverscontrolleradminupdate) | **PATCH** /drivers/{driverId}/admin | [Admin] Update driver profile and sensitive fields
[**driversControllerAssignAssistDriver**](DriversApi.md#driverscontrollerassignassistdriver) | **PATCH** /drivers/assist/{requestId}/assign-driver | [Admin] Assign an assisting driver, keeping the primary driver (MANAGE_ORDERS or MANAGE_DRIVERS)
[**driversControllerAutoAssignAssistDriver**](DriversApi.md#driverscontrollerautoassignassistdriver) | **PATCH** /drivers/assist/{requestId}/auto-assign | [Admin] Auto-assign the nearest eligible driver as the assistant
[**driversControllerCancelAssistRequest**](DriversApi.md#driverscontrollercancelassistrequest) | **PATCH** /drivers/assist/{requestId}/cancel | [Driver] Withdraw my own pending assistance request
[**driversControllerCancelBreak**](DriversApi.md#driverscontrollercancelbreak) | **POST** /drivers/me/break/cancel | Cancel my pending break request
[**driversControllerCreateShift**](DriversApi.md#driverscontrollercreateshift) | **POST** /drivers/me/shifts | Create a shift
[**driversControllerDecideAssistRequest**](DriversApi.md#driverscontrollerdecideassistrequest) | **PATCH** /drivers/assist/{requestId}/decide | [Admin] Approve or reject an assistance request
[**driversControllerDeleteMyShift**](DriversApi.md#driverscontrollerdeletemyshift) | **DELETE** /drivers/me/shifts/{shiftId} | Delete my shift (any status)
[**driversControllerEndBreak**](DriversApi.md#driverscontrollerendbreak) | **POST** /drivers/me/break/end | End the active break (pre-break status restored)
[**driversControllerEndShift**](DriversApi.md#driverscontrollerendshift) | **POST** /drivers/me/shifts/{shiftId}/end | End a shift
[**driversControllerGetActiveBreak**](DriversApi.md#driverscontrollergetactivebreak) | **GET** /drivers/me/break/active | Get my active break, if any
[**driversControllerGetMyBreaks**](DriversApi.md#driverscontrollergetmybreaks) | **GET** /drivers/me/breaks | List my recent breaks
[**driversControllerGetMyProfile**](DriversApi.md#driverscontrollergetmyprofile) | **GET** /drivers/me | Get my driver profile
[**driversControllerGetMyShifts**](DriversApi.md#driverscontrollergetmyshifts) | **GET** /drivers/me/shifts | Get my shifts
[**driversControllerGetWalletBalance**](DriversApi.md#driverscontrollergetwalletbalance) | **GET** /drivers/me/wallet | Get wallet balance
[**driversControllerGetWalletTransactions**](DriversApi.md#driverscontrollergetwallettransactions) | **GET** /drivers/me/wallet/transactions | Get wallet transaction history
[**driversControllerListAssistRequestsForOrder**](DriversApi.md#driverscontrollerlistassistrequestsfororder) | **GET** /drivers/assist/order/{orderId} | [Admin] Assistance requests for one order
[**driversControllerListPendingAssistRequests**](DriversApi.md#driverscontrollerlistpendingassistrequests) | **GET** /drivers/assist/pending | [Admin] Pending extra-driver assistance requests
[**driversControllerMyAssistRequests**](DriversApi.md#driverscontrollermyassistrequests) | **GET** /drivers/assist/mine | [Driver] My assistance requests and their status
[**driversControllerOfferAssistToNearest**](DriversApi.md#driverscontrollerofferassisttonearest) | **PATCH** /drivers/assist/{requestId}/offer-nearest | [Admin] Auto-offer the assist to the top-N nearest eligible drivers
[**driversControllerPendingAssistOffers**](DriversApi.md#driverscontrollerpendingassistoffers) | **GET** /drivers/assist/offers/pending | [Driver] Pending assist offers (HTTP fallback when socket is down)
[**driversControllerRegister**](DriversApi.md#driverscontrollerregister) | **POST** /drivers/register | Register as a driver (creates driver profile, upgrades role)
[**driversControllerRequestAssist**](DriversApi.md#driverscontrollerrequestassist) | **POST** /drivers/assist/{orderId}/groups/{deliveryGroupId}/request | [Driver] Request an additional driver for a delivery I am assigned to
[**driversControllerRequestAssistOrder**](DriversApi.md#driverscontrollerrequestassistorder) | **POST** /drivers/assist/order/{orderId}/request | [Driver] Request an additional driver for a single-vendor order I am assigned to
[**driversControllerRespondToAssistOffer**](DriversApi.md#driverscontrollerrespondtoassistoffer) | **POST** /drivers/assist/{requestId}/offer/respond | [Driver] Accept or decline an assist offer
[**driversControllerStartBreak**](DriversApi.md#driverscontrollerstartbreak) | **POST** /drivers/me/break/start | Request a break (pending admin approval)
[**driversControllerStartShift**](DriversApi.md#driverscontrollerstartshift) | **POST** /drivers/me/shifts/{shiftId}/start | Start a shift (selfie required, must be inside the shift zone, flips ONLINE)
[**driversControllerUpdateProfile**](DriversApi.md#driverscontrollerupdateprofile) | **PATCH** /drivers/me | Update my driver profile
[**driversControllerUpdateStatus**](DriversApi.md#driverscontrollerupdatestatus) | **PATCH** /drivers/me/status | Update driver status (ONLINE / OFFLINE)
[**driversControllerUploadAvatar**](DriversApi.md#driverscontrolleruploadavatar) | **POST** /drivers/me/avatar | Upload driver avatar


# **driversControllerAdminApproveBreak**
> DriversControllerStartBreak200Response driversControllerAdminApproveBreak(breakId)

[Admin] Approve a break request (driver ON_BREAK)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String breakId = breakId_example; // String | 

try {
    final response = api.driversControllerAdminApproveBreak(breakId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminApproveBreak: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **breakId** | **String**|  | 

### Return type

[**DriversControllerStartBreak200Response**](DriversControllerStartBreak200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminCreate**
> ApiControllerRoot200Response driversControllerAdminCreate(adminCreateDriverDto)

[Admin] Create a new driver directly

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final AdminCreateDriverDto adminCreateDriverDto = ; // AdminCreateDriverDto | 

try {
    final response = api.driversControllerAdminCreate(adminCreateDriverDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adminCreateDriverDto** | [**AdminCreateDriverDto**](AdminCreateDriverDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminCreateShift**
> ApiControllerRoot200Response driversControllerAdminCreateShift(driverId, createDriverShiftDto)

[Admin] Create a shift for a driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 
final CreateDriverShiftDto createDriverShiftDto = ; // CreateDriverShiftDto | 

try {
    final response = api.driversControllerAdminCreateShift(driverId, createDriverShiftDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminCreateShift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 
 **createDriverShiftDto** | [**CreateDriverShiftDto**](CreateDriverShiftDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminEndBreak**
> DriversControllerStartBreak200Response driversControllerAdminEndBreak(breakId)

[Admin] Force-end an active break early

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String breakId = breakId_example; // String | 

try {
    final response = api.driversControllerAdminEndBreak(breakId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminEndBreak: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **breakId** | **String**|  | 

### Return type

[**DriversControllerStartBreak200Response**](DriversControllerStartBreak200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminFindAll**
> ApiControllerRoot200Response driversControllerAdminFindAll(status, search, zoneId, page, limit)

[Admin] List all drivers

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String status = status_example; // String | 
final String search = ahmed; // String | 
final String zoneId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.driversControllerAdminFindAll(status, search, zoneId, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 
 **search** | **String**|  | [optional] 
 **zoneId** | **String**|  | [optional] 
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

# **driversControllerAdminFindOne**
> ApiControllerRoot200Response driversControllerAdminFindOne(driverId)

[Admin] Get a driver by ID

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 

try {
    final response = api.driversControllerAdminFindOne(driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminFindOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminGetBreaks**
> DriversControllerGetMyBreaks200Response driversControllerAdminGetBreaks(driverId)

[Admin] List recent breaks for a driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 

try {
    final response = api.driversControllerAdminGetBreaks(driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminGetBreaks: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 

### Return type

[**DriversControllerGetMyBreaks200Response**](DriversControllerGetMyBreaks200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminGetDriverLocation**
> ApiControllerRoot200Response driversControllerAdminGetDriverLocation(driverId)

[Admin] Get a driver current location

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 

try {
    final response = api.driversControllerAdminGetDriverLocation(driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminGetDriverLocation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminGetPendingBreaks**
> DriversControllerGetMyBreaks200Response driversControllerAdminGetPendingBreaks()

[Admin] List pending break requests

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerAdminGetPendingBreaks();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminGetPendingBreaks: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriversControllerGetMyBreaks200Response**](DriversControllerGetMyBreaks200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminGetShifts**
> ApiControllerRoot200Response driversControllerAdminGetShifts(driverId)

[Admin] Get shifts for a driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 

try {
    final response = api.driversControllerAdminGetShifts(driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminGetShifts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminGrantBreak**
> DriversControllerStartBreak200Response driversControllerAdminGrantBreak(driverId, startBreakDto)

[Admin] Grant a break manually (no request needed, quota bypassed)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 
final StartBreakDto startBreakDto = ; // StartBreakDto | 

try {
    final response = api.driversControllerAdminGrantBreak(driverId, startBreakDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminGrantBreak: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 
 **startBreakDto** | [**StartBreakDto**](StartBreakDto.md)|  | 

### Return type

[**DriversControllerStartBreak200Response**](DriversControllerStartBreak200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminRejectBreak**
> DriversControllerStartBreak200Response driversControllerAdminRejectBreak(breakId)

[Admin] Reject a break request

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String breakId = breakId_example; // String | 

try {
    final response = api.driversControllerAdminRejectBreak(breakId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminRejectBreak: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **breakId** | **String**|  | 

### Return type

[**DriversControllerStartBreak200Response**](DriversControllerStartBreak200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminSuspend**
> ApiControllerRoot200Response driversControllerAdminSuspend(driverId)

[Admin] Suspend a driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 

try {
    final response = api.driversControllerAdminSuspend(driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminSuspend: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminUnsuspend**
> ApiControllerRoot200Response driversControllerAdminUnsuspend(driverId)

[Admin] Unsuspend a driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 

try {
    final response = api.driversControllerAdminUnsuspend(driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminUnsuspend: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminUpdate**
> ApiControllerRoot200Response driversControllerAdminUpdate(driverId, adminUpdateDriverDto)

[Admin] Update driver profile and sensitive fields

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 
final AdminUpdateDriverDto adminUpdateDriverDto = ; // AdminUpdateDriverDto | 

try {
    final response = api.driversControllerAdminUpdate(driverId, adminUpdateDriverDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 
 **adminUpdateDriverDto** | [**AdminUpdateDriverDto**](AdminUpdateDriverDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAssignAssistDriver**
> ApiControllerRoot200Response driversControllerAssignAssistDriver(requestId, assignAssistDriverDto)

[Admin] Assign an assisting driver, keeping the primary driver (MANAGE_ORDERS or MANAGE_DRIVERS)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String requestId = requestId_example; // String | 
final AssignAssistDriverDto assignAssistDriverDto = ; // AssignAssistDriverDto | 

try {
    final response = api.driversControllerAssignAssistDriver(requestId, assignAssistDriverDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAssignAssistDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestId** | **String**|  | 
 **assignAssistDriverDto** | [**AssignAssistDriverDto**](AssignAssistDriverDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAutoAssignAssistDriver**
> ApiControllerRoot200Response driversControllerAutoAssignAssistDriver(requestId)

[Admin] Auto-assign the nearest eligible driver as the assistant

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String requestId = requestId_example; // String | 

try {
    final response = api.driversControllerAutoAssignAssistDriver(requestId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAutoAssignAssistDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerCancelAssistRequest**
> ApiControllerRoot200Response driversControllerCancelAssistRequest(requestId)

[Driver] Withdraw my own pending assistance request

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String requestId = requestId_example; // String | 

try {
    final response = api.driversControllerCancelAssistRequest(requestId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerCancelAssistRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerCancelBreak**
> DriversControllerStartBreak200Response driversControllerCancelBreak()

Cancel my pending break request

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerCancelBreak();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerCancelBreak: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriversControllerStartBreak200Response**](DriversControllerStartBreak200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerCreateShift**
> ApiControllerRoot200Response driversControllerCreateShift(createDriverShiftDto)

Create a shift

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final CreateDriverShiftDto createDriverShiftDto = ; // CreateDriverShiftDto | 

try {
    final response = api.driversControllerCreateShift(createDriverShiftDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerCreateShift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createDriverShiftDto** | [**CreateDriverShiftDto**](CreateDriverShiftDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerDecideAssistRequest**
> ApiControllerRoot200Response driversControllerDecideAssistRequest(requestId, decideAssistRequestDto)

[Admin] Approve or reject an assistance request

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String requestId = requestId_example; // String | 
final DecideAssistRequestDto decideAssistRequestDto = ; // DecideAssistRequestDto | 

try {
    final response = api.driversControllerDecideAssistRequest(requestId, decideAssistRequestDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerDecideAssistRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestId** | **String**|  | 
 **decideAssistRequestDto** | [**DecideAssistRequestDto**](DecideAssistRequestDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerDeleteMyShift**
> ApiControllerRoot200Response driversControllerDeleteMyShift(shiftId)

Delete my shift (any status)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String shiftId = shiftId_example; // String | 

try {
    final response = api.driversControllerDeleteMyShift(shiftId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerDeleteMyShift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shiftId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerEndBreak**
> DriversControllerStartBreak200Response driversControllerEndBreak()

End the active break (pre-break status restored)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerEndBreak();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerEndBreak: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriversControllerStartBreak200Response**](DriversControllerStartBreak200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerEndShift**
> ApiControllerRoot200Response driversControllerEndShift(shiftId)

End a shift

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String shiftId = shiftId_example; // String | 

try {
    final response = api.driversControllerEndShift(shiftId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerEndShift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shiftId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerGetActiveBreak**
> DriversControllerStartBreak200Response driversControllerGetActiveBreak()

Get my active break, if any

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerGetActiveBreak();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerGetActiveBreak: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriversControllerStartBreak200Response**](DriversControllerStartBreak200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerGetMyBreaks**
> DriversControllerGetMyBreaks200Response driversControllerGetMyBreaks()

List my recent breaks

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerGetMyBreaks();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerGetMyBreaks: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriversControllerGetMyBreaks200Response**](DriversControllerGetMyBreaks200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerGetMyProfile**
> ApiControllerRoot200Response driversControllerGetMyProfile()

Get my driver profile

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerGetMyProfile();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerGetMyProfile: $e\n');
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

# **driversControllerGetMyShifts**
> ApiControllerRoot200Response driversControllerGetMyShifts()

Get my shifts

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerGetMyShifts();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerGetMyShifts: $e\n');
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

# **driversControllerGetWalletBalance**
> ApiControllerRoot200Response driversControllerGetWalletBalance()

Get wallet balance

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerGetWalletBalance();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerGetWalletBalance: $e\n');
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

# **driversControllerGetWalletTransactions**
> ApiControllerRoot200Response driversControllerGetWalletTransactions(page, limit)

Get wallet transaction history

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.driversControllerGetWalletTransactions(page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerGetWalletTransactions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
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

# **driversControllerListAssistRequestsForOrder**
> DriversControllerMyAssistRequests200Response driversControllerListAssistRequestsForOrder(orderId)

[Admin] Assistance requests for one order

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String orderId = orderId_example; // String | 

try {
    final response = api.driversControllerListAssistRequestsForOrder(orderId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerListAssistRequestsForOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 

### Return type

[**DriversControllerMyAssistRequests200Response**](DriversControllerMyAssistRequests200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerListPendingAssistRequests**
> DriversControllerMyAssistRequests200Response driversControllerListPendingAssistRequests()

[Admin] Pending extra-driver assistance requests

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerListPendingAssistRequests();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerListPendingAssistRequests: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriversControllerMyAssistRequests200Response**](DriversControllerMyAssistRequests200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerMyAssistRequests**
> DriversControllerMyAssistRequests200Response driversControllerMyAssistRequests()

[Driver] My assistance requests and their status

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerMyAssistRequests();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerMyAssistRequests: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriversControllerMyAssistRequests200Response**](DriversControllerMyAssistRequests200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerOfferAssistToNearest**
> ApiControllerRoot200Response driversControllerOfferAssistToNearest(requestId, limit)

[Admin] Auto-offer the assist to the top-N nearest eligible drivers

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String requestId = requestId_example; // String | 
final String limit = limit_example; // String | 

try {
    final response = api.driversControllerOfferAssistToNearest(requestId, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerOfferAssistToNearest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestId** | **String**|  | 
 **limit** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerPendingAssistOffers**
> DriversControllerMyAssistRequests200Response driversControllerPendingAssistOffers()

[Driver] Pending assist offers (HTTP fallback when socket is down)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerPendingAssistOffers();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerPendingAssistOffers: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriversControllerMyAssistRequests200Response**](DriversControllerMyAssistRequests200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerRegister**
> ApiControllerRoot200Response driversControllerRegister(registerDriverDto)

Register as a driver (creates driver profile, upgrades role)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final RegisterDriverDto registerDriverDto = ; // RegisterDriverDto | 

try {
    final response = api.driversControllerRegister(registerDriverDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerRegister: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerDriverDto** | [**RegisterDriverDto**](RegisterDriverDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerRequestAssist**
> ApiControllerRoot200Response driversControllerRequestAssist(orderId, deliveryGroupId, requestAssistDriverDto)

[Driver] Request an additional driver for a delivery I am assigned to

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String orderId = orderId_example; // String | 
final String deliveryGroupId = deliveryGroupId_example; // String | 
final RequestAssistDriverDto requestAssistDriverDto = ; // RequestAssistDriverDto | 

try {
    final response = api.driversControllerRequestAssist(orderId, deliveryGroupId, requestAssistDriverDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerRequestAssist: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **deliveryGroupId** | **String**|  | 
 **requestAssistDriverDto** | [**RequestAssistDriverDto**](RequestAssistDriverDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerRequestAssistOrder**
> ApiControllerRoot200Response driversControllerRequestAssistOrder(orderId, requestAssistDriverDto)

[Driver] Request an additional driver for a single-vendor order I am assigned to

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String orderId = orderId_example; // String | 
final RequestAssistDriverDto requestAssistDriverDto = ; // RequestAssistDriverDto | 

try {
    final response = api.driversControllerRequestAssistOrder(orderId, requestAssistDriverDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerRequestAssistOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **requestAssistDriverDto** | [**RequestAssistDriverDto**](RequestAssistDriverDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerRespondToAssistOffer**
> ApiControllerRoot200Response driversControllerRespondToAssistOffer(requestId)

[Driver] Accept or decline an assist offer

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String requestId = requestId_example; // String | 

try {
    final response = api.driversControllerRespondToAssistOffer(requestId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerRespondToAssistOffer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerStartBreak**
> DriversControllerStartBreak200Response driversControllerStartBreak(startBreakDto)

Request a break (pending admin approval)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final StartBreakDto startBreakDto = ; // StartBreakDto | 

try {
    final response = api.driversControllerStartBreak(startBreakDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerStartBreak: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **startBreakDto** | [**StartBreakDto**](StartBreakDto.md)|  | 

### Return type

[**DriversControllerStartBreak200Response**](DriversControllerStartBreak200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerStartShift**
> ApiControllerRoot200Response driversControllerStartShift(shiftId, file)

Start a shift (selfie required, must be inside the shift zone, flips ONLINE)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String shiftId = shiftId_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.driversControllerStartShift(shiftId, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerStartShift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shiftId** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerUpdateProfile**
> ApiControllerRoot200Response driversControllerUpdateProfile(updateDriverProfileDto)

Update my driver profile

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final UpdateDriverProfileDto updateDriverProfileDto = ; // UpdateDriverProfileDto | 

try {
    final response = api.driversControllerUpdateProfile(updateDriverProfileDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerUpdateProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateDriverProfileDto** | [**UpdateDriverProfileDto**](UpdateDriverProfileDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerUpdateStatus**
> ApiControllerRoot200Response driversControllerUpdateStatus(updateDriverStatusDto)

Update driver status (ONLINE / OFFLINE)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final UpdateDriverStatusDto updateDriverStatusDto = ; // UpdateDriverStatusDto | 

try {
    final response = api.driversControllerUpdateStatus(updateDriverStatusDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerUpdateStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateDriverStatusDto** | [**UpdateDriverStatusDto**](UpdateDriverStatusDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerUploadAvatar**
> ApiControllerRoot200Response driversControllerUploadAvatar(file)

Upload driver avatar

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.driversControllerUploadAvatar(file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerUploadAvatar: $e\n');
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

