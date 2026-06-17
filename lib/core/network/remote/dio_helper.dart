import 'package:dio/dio.dart';

String url = const String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://redosyria.napoltech.com',
);

class DioHelper {
  static Dio? dio;

  static init() {
    dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: Duration(seconds: 5),
        //  receiveDataWhenStatusError: true,
      ),
    );
    // dio?.interceptors.add(
    //   AwesomeDioInterceptor(
    //     logRequestTimeout: false,
    //     logResponseHeaders: false,
    //   ),
    // );
  }

  static Future<Response> getData({
    required String url,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    dio!.options.headers = {
      'Authorization': token ?? '',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    return await dio!.get(url, queryParameters: query);
  }

  static Future<Response> postData({
    required String url,
    Object? data,
    String? token,
    Options? options,
  }) async {
    dio!.options.headers = {
      'Authorization': token ?? '',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    return dio!.post(url, data: data, options: options);
  }

  static Future<Response> putData({
    required String url,
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    dio!.options.headers = {
      'Authorization': token ?? '',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    return dio!.put(url, queryParameters: query, data: data);
  }

  static Future<Response> patchData({
    required String url,
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    dio!.options.headers = {
      'Authorization': token ?? '',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    return dio!.patch(url, queryParameters: query, data: data);
  }

  static Future<Response> deleteData({
    required String url,
    String? token,
    Map<String, dynamic>? data,
  }) async {
    dio!.options.headers = {
      'Authorization': token ?? '',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    return dio!.delete(url, data: data);
  }
}
