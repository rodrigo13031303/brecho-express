import 'package:dio/dio.dart';

class DioClient {
  final Dio dio;

  DioClient({Dio? dio}) : dio = dio ?? Dio();
}
