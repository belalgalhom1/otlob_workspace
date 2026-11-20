# api.api.DriverRankingApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**driverRankingControllerGetDriverHistory**](DriverRankingApi.md#driverrankingcontrollergetdriverhistory) | **GET** /driver-ranking/drivers/{driverId}/history | [Admin] Get a driver&#39;s ranking &amp; override history
[**driverRankingControllerGetMyRankSummary**](DriverRankingApi.md#driverrankingcontrollergetmyranksummary) | **GET** /driver-ranking/me | Get current driver badge, current week progress, next evaluation time, and history
[**driverRankingControllerGetRunDetails**](DriverRankingApi.md#driverrankingcontrollergetrundetails) | **GET** /driver-ranking/runs/{runId} | [Admin] Get a weekly driver ranking run and its driver entries
[**driverRankingControllerGetScheduleStatus**](DriverRankingApi.md#driverrankingcontrollergetschedulestatus) | **GET** /driver-ranking/schedule | [Admin] Get weekly driver ranking evaluation schedule &amp; next run timestamp
[**driverRankingControllerListIncidents**](DriverRankingApi.md#driverrankingcontrollerlistincidents) | **GET** /driver-ranking/incidents | [Admin] List delivery cancellation &amp; reassignment responsibility incidents
[**driverRankingControllerListRuns**](DriverRankingApi.md#driverrankingcontrollerlistruns) | **GET** /driver-ranking/runs | [Admin] List weekly driver ranking evaluation runs
[**driverRankingControllerOverrideDriverTier**](DriverRankingApi.md#driverrankingcontrolleroverridedrivertier) | **POST** /driver-ranking/drivers/{driverId}/override | [Admin] Manually override a driver badge with mandatory audit reason
[**driverRankingControllerPreviewEvaluation**](DriverRankingApi.md#driverrankingcontrollerpreviewevaluation) | **GET** /driver-ranking/preview | [Admin] Dry-run preview of previous completed week ranking results without modifying badges
[**driverRankingControllerRetryFailedRun**](DriverRankingApi.md#driverrankingcontrollerretryfailedrun) | **POST** /driver-ranking/runs/{runId}/retry | [Admin] Safely resume/retry a failed weekly evaluation run without duplicating already-committed entries
[**driverRankingControllerReviewIncident**](DriverRankingApi.md#driverrankingcontrollerreviewincident) | **PATCH** /driver-ranking/incidents/{incidentId} | [Admin] Update/resolve a delivery incident responsibility classification
[**driverRankingControllerRunEvaluationNow**](DriverRankingApi.md#driverrankingcontrollerrunevaluationnow) | **POST** /driver-ranking/run | [Admin] Execute weekly driver ranking evaluation immediately for the previous completed week


# **driverRankingControllerGetDriverHistory**
> DriverRankingControllerGetDriverHistory200Response driverRankingControllerGetDriverHistory(driverId, page, limit)

[Admin] Get a driver's ranking & override history

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverRankingApi();
final String driverId = driverId_example; // String | 
final num page = 8.14; // num | 
final num limit = 8.14; // num | 

try {
    final response = api.driverRankingControllerGetDriverHistory(driverId, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverRankingApi->driverRankingControllerGetDriverHistory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**DriverRankingControllerGetDriverHistory200Response**](DriverRankingControllerGetDriverHistory200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverRankingControllerGetMyRankSummary**
> DriverRankingControllerGetMyRankSummary200Response driverRankingControllerGetMyRankSummary()

Get current driver badge, current week progress, next evaluation time, and history

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverRankingApi();

try {
    final response = api.driverRankingControllerGetMyRankSummary();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverRankingApi->driverRankingControllerGetMyRankSummary: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriverRankingControllerGetMyRankSummary200Response**](DriverRankingControllerGetMyRankSummary200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverRankingControllerGetRunDetails**
> DriverRankingControllerGetRunDetails200Response driverRankingControllerGetRunDetails(runId, page, limit, search, tier)

[Admin] Get a weekly driver ranking run and its driver entries

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverRankingApi();
final String runId = runId_example; // String | 
final num page = 8.14; // num | 
final num limit = 8.14; // num | 
final String search = search_example; // String | 
final DriverTier tier = ; // DriverTier | 

try {
    final response = api.driverRankingControllerGetRunDetails(runId, page, limit, search, tier);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverRankingApi->driverRankingControllerGetRunDetails: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **runId** | **String**|  | 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 50]
 **search** | **String**|  | [optional] 
 **tier** | [**DriverTier**](.md)|  | [optional] 

### Return type

[**DriverRankingControllerGetRunDetails200Response**](DriverRankingControllerGetRunDetails200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverRankingControllerGetScheduleStatus**
> DriverRankingControllerGetScheduleStatus200Response driverRankingControllerGetScheduleStatus()

[Admin] Get weekly driver ranking evaluation schedule & next run timestamp

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverRankingApi();

try {
    final response = api.driverRankingControllerGetScheduleStatus();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverRankingApi->driverRankingControllerGetScheduleStatus: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriverRankingControllerGetScheduleStatus200Response**](DriverRankingControllerGetScheduleStatus200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverRankingControllerListIncidents**
> DriverRankingControllerListIncidents200Response driverRankingControllerListIncidents(page, limit, responsibility, driverId)

[Admin] List delivery cancellation & reassignment responsibility incidents

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverRankingApi();
final num page = 8.14; // num | 
final num limit = 8.14; // num | 
final DeliveryIncidentResponsibility responsibility = ; // DeliveryIncidentResponsibility | 
final String driverId = driverId_example; // String | 

try {
    final response = api.driverRankingControllerListIncidents(page, limit, responsibility, driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverRankingApi->driverRankingControllerListIncidents: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]
 **responsibility** | [**DeliveryIncidentResponsibility**](.md)|  | [optional] 
 **driverId** | **String**|  | [optional] 

### Return type

[**DriverRankingControllerListIncidents200Response**](DriverRankingControllerListIncidents200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverRankingControllerListRuns**
> DriverRankingControllerListRuns200Response driverRankingControllerListRuns(page, limit)

[Admin] List weekly driver ranking evaluation runs

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverRankingApi();
final num page = 8.14; // num | 
final num limit = 8.14; // num | 

try {
    final response = api.driverRankingControllerListRuns(page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverRankingApi->driverRankingControllerListRuns: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**DriverRankingControllerListRuns200Response**](DriverRankingControllerListRuns200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverRankingControllerOverrideDriverTier**
> DriverRankingControllerOverrideDriverTier200Response driverRankingControllerOverrideDriverTier(driverId, overrideDriverRankDto)

[Admin] Manually override a driver badge with mandatory audit reason

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverRankingApi();
final String driverId = driverId_example; // String | 
final OverrideDriverRankDto overrideDriverRankDto = ; // OverrideDriverRankDto | 

try {
    final response = api.driverRankingControllerOverrideDriverTier(driverId, overrideDriverRankDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverRankingApi->driverRankingControllerOverrideDriverTier: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 
 **overrideDriverRankDto** | [**OverrideDriverRankDto**](OverrideDriverRankDto.md)|  | 

### Return type

[**DriverRankingControllerOverrideDriverTier200Response**](DriverRankingControllerOverrideDriverTier200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverRankingControllerPreviewEvaluation**
> DriverRankingControllerPreviewEvaluation200Response driverRankingControllerPreviewEvaluation(page, limit, search, tier)

[Admin] Dry-run preview of previous completed week ranking results without modifying badges

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverRankingApi();
final num page = 8.14; // num | 
final num limit = 8.14; // num | 
final String search = search_example; // String | 
final DriverTier tier = ; // DriverTier | 

try {
    final response = api.driverRankingControllerPreviewEvaluation(page, limit, search, tier);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverRankingApi->driverRankingControllerPreviewEvaluation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 50]
 **search** | **String**|  | [optional] 
 **tier** | [**DriverTier**](.md)|  | [optional] 

### Return type

[**DriverRankingControllerPreviewEvaluation200Response**](DriverRankingControllerPreviewEvaluation200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverRankingControllerRetryFailedRun**
> DriverRankingControllerRunEvaluationNow200Response driverRankingControllerRetryFailedRun(runId)

[Admin] Safely resume/retry a failed weekly evaluation run without duplicating already-committed entries

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverRankingApi();
final String runId = runId_example; // String | 

try {
    final response = api.driverRankingControllerRetryFailedRun(runId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverRankingApi->driverRankingControllerRetryFailedRun: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **runId** | **String**|  | 

### Return type

[**DriverRankingControllerRunEvaluationNow200Response**](DriverRankingControllerRunEvaluationNow200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverRankingControllerReviewIncident**
> DriverRankingControllerReviewIncident200Response driverRankingControllerReviewIncident(incidentId, updateDeliveryIncidentDto)

[Admin] Update/resolve a delivery incident responsibility classification

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverRankingApi();
final String incidentId = incidentId_example; // String | 
final UpdateDeliveryIncidentDto updateDeliveryIncidentDto = ; // UpdateDeliveryIncidentDto | 

try {
    final response = api.driverRankingControllerReviewIncident(incidentId, updateDeliveryIncidentDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverRankingApi->driverRankingControllerReviewIncident: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **incidentId** | **String**|  | 
 **updateDeliveryIncidentDto** | [**UpdateDeliveryIncidentDto**](UpdateDeliveryIncidentDto.md)|  | 

### Return type

[**DriverRankingControllerReviewIncident200Response**](DriverRankingControllerReviewIncident200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverRankingControllerRunEvaluationNow**
> DriverRankingControllerRunEvaluationNow200Response driverRankingControllerRunEvaluationNow()

[Admin] Execute weekly driver ranking evaluation immediately for the previous completed week

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverRankingApi();

try {
    final response = api.driverRankingControllerRunEvaluationNow();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverRankingApi->driverRankingControllerRunEvaluationNow: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriverRankingControllerRunEvaluationNow200Response**](DriverRankingControllerRunEvaluationNow200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

