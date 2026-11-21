library;

export 'src/network/dio_client.dart';
export 'src/network/auth_interceptor.dart';
export 'src/network/push_notification_service.dart';
export 'src/network/connectivity_service.dart';
export 'src/auth/token_service.dart';
export 'src/providers/core_providers.dart';
export 'src/providers/api_providers.dart';
export 'src/config/media_config_service.dart';
export 'src/config/env_config.dart';
export 'src/providers/locale_provider.dart';
export 'src/providers/theme_provider.dart';
export 'src/location/location_service.dart';
export 'src/localization/bilingual_helper.dart';
export 'src/localization/api_error_mapper.dart';
export 'src/socket/socket_events.dart';
export 'src/socket/socket_service.dart';
export 'src/socket/order_revision.dart';
export 'src/permissions/permission_service.dart';
export 'src/location/road_route_utils.dart';
// export 'src/models/paginated_result.dart';
export 'src/utils/image_utils.dart';
export 'src/utils/order_activity_helper.dart';
export 'src/utils/order_type_helper.dart';
export 'src/utils/vehicle_type_helper.dart';
export 'src/utils/ios_alert_helper.dart';
export 'src/utils/phone_utils.dart';

// Third-party infrastructure exports for unified versions across apps
export 'package:firebase_core/firebase_core.dart';
export 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart' show InternetStatus;
export 'package:dio/dio.dart' show CancelToken, Dio, DioException, DioExceptionType, FormData, MultipartFile;
