# api.api.VendorsMembersTeamApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorMembersControllerAddMember**](VendorsMembersTeamApi.md#vendormemberscontrolleraddmember) | **POST** /vendors/{vendorId}/members | Add a new member to the vendor
[**vendorMembersControllerAdminAddMember**](VendorsMembersTeamApi.md#vendormemberscontrolleradminaddmember) | **POST** /vendors/{vendorId}/members/admin | Add a new member to a vendor (Admin Override)
[**vendorMembersControllerAdminRemoveMember**](VendorsMembersTeamApi.md#vendormemberscontrolleradminremovemember) | **DELETE** /vendors/{vendorId}/members/admin/{memberId} | Remove a member from a vendor (Admin Override)
[**vendorMembersControllerFindAll**](VendorsMembersTeamApi.md#vendormemberscontrollerfindall) | **GET** /vendors/{vendorId}/members | List all members of a vendor
[**vendorMembersControllerRemoveMember**](VendorsMembersTeamApi.md#vendormemberscontrollerremovemember) | **DELETE** /vendors/{vendorId}/members/{memberId} | Remove a member from the vendor
[**vendorMembersControllerUpdateRole**](VendorsMembersTeamApi.md#vendormemberscontrollerupdaterole) | **PATCH** /vendors/{vendorId}/members/{memberId}/role | Update a member&#39;s role


# **vendorMembersControllerAddMember**
> AuthControllerRegister200Response vendorMembersControllerAddMember(vendorId, addVendorMemberDto)

Add a new member to the vendor

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMembersTeamApi();
final String vendorId = vendorId_example; // String | 
final AddVendorMemberDto addVendorMemberDto = ; // AddVendorMemberDto | 

try {
    final response = api.vendorMembersControllerAddMember(vendorId, addVendorMemberDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMembersTeamApi->vendorMembersControllerAddMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **addVendorMemberDto** | [**AddVendorMemberDto**](AddVendorMemberDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorMembersControllerAdminAddMember**
> AuthControllerRegister200Response vendorMembersControllerAdminAddMember(vendorId, addVendorMemberDto)

Add a new member to a vendor (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMembersTeamApi();
final String vendorId = vendorId_example; // String | 
final AddVendorMemberDto addVendorMemberDto = ; // AddVendorMemberDto | 

try {
    final response = api.vendorMembersControllerAdminAddMember(vendorId, addVendorMemberDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMembersTeamApi->vendorMembersControllerAdminAddMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **addVendorMemberDto** | [**AddVendorMemberDto**](AddVendorMemberDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorMembersControllerAdminRemoveMember**
> AuthControllerRegister200Response vendorMembersControllerAdminRemoveMember(vendorId, memberId)

Remove a member from a vendor (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMembersTeamApi();
final String vendorId = vendorId_example; // String | 
final String memberId = memberId_example; // String | 

try {
    final response = api.vendorMembersControllerAdminRemoveMember(vendorId, memberId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMembersTeamApi->vendorMembersControllerAdminRemoveMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **memberId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorMembersControllerFindAll**
> AuthControllerRegister200Response vendorMembersControllerFindAll(vendorId)

List all members of a vendor

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMembersTeamApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.vendorMembersControllerFindAll(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMembersTeamApi->vendorMembersControllerFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorMembersControllerRemoveMember**
> AuthControllerRegister200Response vendorMembersControllerRemoveMember(vendorId, memberId)

Remove a member from the vendor

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMembersTeamApi();
final String vendorId = vendorId_example; // String | 
final String memberId = memberId_example; // String | 

try {
    final response = api.vendorMembersControllerRemoveMember(vendorId, memberId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMembersTeamApi->vendorMembersControllerRemoveMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **memberId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorMembersControllerUpdateRole**
> AuthControllerRegister200Response vendorMembersControllerUpdateRole(vendorId, memberId, updateVendorMemberRoleDto)

Update a member's role

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMembersTeamApi();
final String vendorId = vendorId_example; // String | 
final String memberId = memberId_example; // String | 
final UpdateVendorMemberRoleDto updateVendorMemberRoleDto = ; // UpdateVendorMemberRoleDto | 

try {
    final response = api.vendorMembersControllerUpdateRole(vendorId, memberId, updateVendorMemberRoleDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMembersTeamApi->vendorMembersControllerUpdateRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **memberId** | **String**|  | 
 **updateVendorMemberRoleDto** | [**UpdateVendorMemberRoleDto**](UpdateVendorMemberRoleDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

