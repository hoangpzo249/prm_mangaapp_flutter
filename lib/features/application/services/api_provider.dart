import 'package:flutter/foundation.dart';

import '../../../core/networks/api_client.dart';
import 'storage_service.dart';

/// Shared API client.
///
/// Override the URL when running on a physical device:
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.3:9999/api
class ApiProvider {
  ApiProvider._();

  // static const String localIp = '192.168.1.141';
  static const String baseUrl = 'http://10.33.57.144:9999/api';

  static final ApiClient client = ApiClient(
    baseUrl: baseUrl,
    tokenProvider: StorageService.instance.getToken,
  );
}
