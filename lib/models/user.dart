class User {
  final String email;
  final String? password;
  final String? username;
  final String nickname;
  final String? profileImg;
  final String? phone;
  final DateTime? birthday;
  final DateTime? joinAt;

  //생성자, required 필수값
  User ({
    required this.email,
    this.password,
    this.username,
    required this.nickname,
    this.profileImg = '-',
    this.phone,
    this.birthday,
    this.joinAt
  });

  // json ==> dto 변환기
  factory User.fromJson(Map<String, dynamic> j) => User (
    email: j['email'] ?? '',
    //null일 때 대체값
    password: j['password'] ?? '',
    username: j['username'] ?? '',
    nickname: j['nickname'] ?? '',
    profileImg: j['profileImg'] ?? '-',
    phone: j['phone'] ?? '',
    birthday: j['birthday'] != null ? DateTime.parse(j['birthday']) : null,
    joinAt: j['joinAt'] != null ? DateTime.parse(j['joinAt']) : null,
  );

  //mapp => json 변환기
  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'username': username,
    'nickname': nickname,
    if(profileImg != null) 'profileImg': profileImg,
    'phone': phone,
    'birthday': birthday?.toIso8601String(),
    'joinAt': joinAt?.toIso8601String(),
  };
}