// import '../../../core/networks/api_client.dart';
// import 'storage_service.dart';

// /// Single shared [ApiClient] instance. Points at the same host as the RN app.
// class ApiProvider {
//   ApiProvider._();

//   static const String localIp = '192.168.1.3';
//   static const String baseUrl = 'http://$localIp:9999/api';

//   static final ApiClient client = ApiClient(
//     baseUrl: baseUrl,
//     tokenProvider: StorageService.instance.getToken,
//   );
// }


import 'package:flutter/foundation.dart' show kIsWeb;
 
import '../../../core/networks/api_client.dart';
import 'storage_service.dart';
 
/// Single shared [ApiClient] instance.
///
/// Base host thay đổi tuỳ môi trường chạy:
/// - Chạy trên web (Chrome/Edge)  -> 'localhost' (cùng máy với server)
/// - Chạy trên Android Emulator   -> '10.0.2.2'   (alias trỏ về localhost máy host)
/// - Chạy trên thiết bị thật (điện thoại qua Wi-Fi) -> IP LAN của máy chạy server,
///   ví dụ '192.168.1.3'. Sửa trực tiếp biến `_host` bên dưới khi test bằng máy thật.
class ApiProvider {
  ApiProvider._();
 
  static const String _host = kIsWeb ? 'localhost' : '10.33.57.83';
  static const String baseUrl = 'http://$_host:9999/api';
 
  static final ApiClient client = ApiClient(
    baseUrl: baseUrl,
    tokenProvider: StorageService.instance.getToken,
  );
}