class AppConfig {
  static const bool isProd = bool.fromEnvironment('dart.vm.product');

  static const String baseUrl = isProd
      ? 'https://homesweethome.koyeb.app/api' // 배포 서버
      : 'http://10.0.2.2:8080/api';           // 개발용 서버
}