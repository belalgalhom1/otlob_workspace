# api.api.LegalDocumentsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**legalDocumentsControllerAcceptDocument**](LegalDocumentsApi.md#legaldocumentscontrolleracceptdocument) | **POST** /legal-documents/accept | Accept a legal document version (records user acceptance and timestamp)
[**legalDocumentsControllerCreateDocument**](LegalDocumentsApi.md#legaldocumentscontrollercreatedocument) | **POST** /legal-documents/admin | Create a new legal document draft (Admin)
[**legalDocumentsControllerDeleteDocument**](LegalDocumentsApi.md#legaldocumentscontrollerdeletedocument) | **DELETE** /legal-documents/admin/{id} | Soft-delete a legal document (Admin)
[**legalDocumentsControllerGetAcceptanceStatus**](LegalDocumentsApi.md#legaldocumentscontrollergetacceptancestatus) | **GET** /legal-documents/acceptance-status | Check if authenticated user needs to accept the latest Terms of Use
[**legalDocumentsControllerGetActiveDocument**](LegalDocumentsApi.md#legaldocumentscontrollergetactivedocument) | **GET** /legal-documents/active/{type} | Get the currently active, published legal document (Terms or Privacy)
[**legalDocumentsControllerGetAllDocuments**](LegalDocumentsApi.md#legaldocumentscontrollergetalldocuments) | **GET** /legal-documents/admin/all | List all legal documents (drafts, published, archived) with stats (Admin)
[**legalDocumentsControllerGetDocumentById**](LegalDocumentsApi.md#legaldocumentscontrollergetdocumentbyid) | **GET** /legal-documents/admin/{id} | Get single legal document details by ID (Admin)
[**legalDocumentsControllerGetDocumentStats**](LegalDocumentsApi.md#legaldocumentscontrollergetdocumentstats) | **GET** /legal-documents/admin/{id}/stats | Get user acceptance metrics and role breakdown for a document (Admin)
[**legalDocumentsControllerPublishDocument**](LegalDocumentsApi.md#legaldocumentscontrollerpublishdocument) | **POST** /legal-documents/admin/{id}/publish | Publish legal document version (unpublishes older versions of same type) (Admin)
[**legalDocumentsControllerUpdateDocument**](LegalDocumentsApi.md#legaldocumentscontrollerupdatedocument) | **PATCH** /legal-documents/admin/{id} | Update legal document details (Admin)


# **legalDocumentsControllerAcceptDocument**
> ApiControllerRoot200Response legalDocumentsControllerAcceptDocument(acceptLegalDocumentDto)

Accept a legal document version (records user acceptance and timestamp)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLegalDocumentsApi();
final AcceptLegalDocumentDto acceptLegalDocumentDto = ; // AcceptLegalDocumentDto | 

try {
    final response = api.legalDocumentsControllerAcceptDocument(acceptLegalDocumentDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LegalDocumentsApi->legalDocumentsControllerAcceptDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **acceptLegalDocumentDto** | [**AcceptLegalDocumentDto**](AcceptLegalDocumentDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalDocumentsControllerCreateDocument**
> ApiControllerRoot200Response legalDocumentsControllerCreateDocument(createLegalDocumentDto)

Create a new legal document draft (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLegalDocumentsApi();
final CreateLegalDocumentDto createLegalDocumentDto = ; // CreateLegalDocumentDto | 

try {
    final response = api.legalDocumentsControllerCreateDocument(createLegalDocumentDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LegalDocumentsApi->legalDocumentsControllerCreateDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createLegalDocumentDto** | [**CreateLegalDocumentDto**](CreateLegalDocumentDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalDocumentsControllerDeleteDocument**
> ApiControllerRoot200Response legalDocumentsControllerDeleteDocument(id)

Soft-delete a legal document (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLegalDocumentsApi();
final String id = id_example; // String | 

try {
    final response = api.legalDocumentsControllerDeleteDocument(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LegalDocumentsApi->legalDocumentsControllerDeleteDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalDocumentsControllerGetAcceptanceStatus**
> ApiControllerRoot200Response legalDocumentsControllerGetAcceptanceStatus()

Check if authenticated user needs to accept the latest Terms of Use

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLegalDocumentsApi();

try {
    final response = api.legalDocumentsControllerGetAcceptanceStatus();
    print(response);
} on DioException catch (e) {
    print('Exception when calling LegalDocumentsApi->legalDocumentsControllerGetAcceptanceStatus: $e\n');
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

# **legalDocumentsControllerGetActiveDocument**
> ApiControllerRoot200Response legalDocumentsControllerGetActiveDocument(type)

Get the currently active, published legal document (Terms or Privacy)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLegalDocumentsApi();
final String type = type_example; // String | 

try {
    final response = api.legalDocumentsControllerGetActiveDocument(type);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LegalDocumentsApi->legalDocumentsControllerGetActiveDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalDocumentsControllerGetAllDocuments**
> ApiControllerRoot200Response legalDocumentsControllerGetAllDocuments(type)

List all legal documents (drafts, published, archived) with stats (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLegalDocumentsApi();
final String type = type_example; // String | 

try {
    final response = api.legalDocumentsControllerGetAllDocuments(type);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LegalDocumentsApi->legalDocumentsControllerGetAllDocuments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalDocumentsControllerGetDocumentById**
> ApiControllerRoot200Response legalDocumentsControllerGetDocumentById(id)

Get single legal document details by ID (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLegalDocumentsApi();
final String id = id_example; // String | 

try {
    final response = api.legalDocumentsControllerGetDocumentById(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LegalDocumentsApi->legalDocumentsControllerGetDocumentById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalDocumentsControllerGetDocumentStats**
> ApiControllerRoot200Response legalDocumentsControllerGetDocumentStats(id)

Get user acceptance metrics and role breakdown for a document (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLegalDocumentsApi();
final String id = id_example; // String | 

try {
    final response = api.legalDocumentsControllerGetDocumentStats(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LegalDocumentsApi->legalDocumentsControllerGetDocumentStats: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalDocumentsControllerPublishDocument**
> ApiControllerRoot200Response legalDocumentsControllerPublishDocument(id)

Publish legal document version (unpublishes older versions of same type) (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLegalDocumentsApi();
final String id = id_example; // String | 

try {
    final response = api.legalDocumentsControllerPublishDocument(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LegalDocumentsApi->legalDocumentsControllerPublishDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalDocumentsControllerUpdateDocument**
> ApiControllerRoot200Response legalDocumentsControllerUpdateDocument(id, updateLegalDocumentDto)

Update legal document details (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLegalDocumentsApi();
final String id = id_example; // String | 
final UpdateLegalDocumentDto updateLegalDocumentDto = ; // UpdateLegalDocumentDto | 

try {
    final response = api.legalDocumentsControllerUpdateDocument(id, updateLegalDocumentDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LegalDocumentsApi->legalDocumentsControllerUpdateDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateLegalDocumentDto** | [**UpdateLegalDocumentDto**](UpdateLegalDocumentDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

