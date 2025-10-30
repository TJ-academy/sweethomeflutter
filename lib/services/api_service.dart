import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

//Dio + 쿠키로 Spring 세션 관리를 담당하는 공용 API 클라이언트

class ApiService {
  late Dio dio;
  late PersistCookieJar cookieJar;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080/api',
      //baseUrl: 'https://homesweethome.koyeb.app/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.formUrlEncodedContentType,
    ));
  }

  /// 초기화 (쿠키 지속 저장용)
  Future<void> init() async {
    Directory dir = await getApplicationDocumentsDirectory();
    cookieJar = PersistCookieJar(storage: FileStorage("${dir.path}/.cookies/"));
    dio.interceptors.add(CookieManager(cookieJar));
  }

  /// GET
  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return await dio.get(path, queryParameters: params);
  }

  /// POST
  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  /// 로그아웃 또는 쿠키 초기화 시
  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
  }


}