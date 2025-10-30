// import 'package:flutter/material.dart';
//
// import '../services/api_service.dart';
//
// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});
//
//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }
//
// class _SignUpPageState extends State<SignUpPage> {
//   final api = ApiService();
//
//   final emailCtrl = TextEditingController();
//   final pwCtrl = TextEditingController();
//   final usernameCtrl = TextEditingController();
//   final nicknameCtrl = TextEditingController();
//   final profileImgCtrl = TextEditingController();
//   final phoneCtrl = TextEditingController();
//   DateTime? birthday;
//
//   bool loading = false;
//   bool emailVerified = false;
//   bool nicknameChecked = false;
//   String emailStatus = '';
//   String nicknameStatus = '';
//
//   // 전화번호 자동 하이픈
//   void formatPhone(String value) {
//     final numbers = value.replaceAll(RegExp(r'\D'), '');
//     if (numbers.length >= 10) {
//       final formatted = numbers.length == 10
//           ? '${numbers.substring(0, 3)}-${numbers.substring(3, 6)}-${numbers.substring(6)}'
//           : '${numbers.substring(0, 3)}-${numbers.substring(3, 7)}-${numbers.substring(7)}';
//       phoneCtrl.value = TextEditingValue(
//         text: formatted,
//         selection: TextSelection.collapsed(offset: formatted.length),
//       );
//     }
//   }
//
//   // 이메일 중복 확인 + 인증 코드 요청
//   Future<void> verifyEmail() async {
//     final email = emailCtrl.text.trim();
//     final result = await api.checkEmailDuplicate(email);
//     if (result == 'duplicate') {
//       setState(() {
//         emailStatus = '이미 존재하는 이메일입니다.';
//         emailVerified = false;
//       });
//       return;
//     }
//
//     final res = await api.sendVerificationCode(email);
//     setState(() {
//       emailVerified = res == '메일이 전송되었습니다.';
//       emailStatus = res;
//     });
//   }
//
//   // 닉네임 중복 확인
//   Future<void> checkNickname() async {
//     final nickname = nicknameCtrl.text.trim();
//     final res = await api.checkNicknameDuplicate(nickname);
//     setState(() {
//       nicknameChecked = res == 'ok';
//       nicknameStatus = nicknameChecked ? '사용 가능한 닉네임입니다.' : '이미 사용 중인 닉네임입니다.';
//     });
//   }
//
//   //회원가입
//   Future<void> _submit() async {
//     if (!emailVerified || !nicknameChecked) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('이메일 인증과 닉네임 중복 확인을 완료해주세요.')),
//       );
//       return;
//     }
//
//     final user = User (
//       email: emailCtrl.text.trim(),
//       password: pwCtrl.text,
//       username: usernameCtrl.text.trim(),
//       nickname: nicknameCtrl.text.trim(),
//       profileImg: profileImgCtrl.text.trim().isEmpty ? "-" : profileImgCtrl.text.trim(),
//       phone: phoneCtrl.text.trim(),
//       birthday: birthday?.toIso8601String() ?? '',
//     );
//
//     setState(() => loading = true);
//     final ok = await api.signUp(user);
//     setState(() => loading= false);
//
//     if(ok && mounted) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(
//           const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인 해주세요.'))
//       );
//       Navigator.pop(context);
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('회원가입 실패했습니다.')));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('회원가입')),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           TextField(
//             controller: emailCtrl,
//             decoration: const InputDecoration(labelText: '이메일'),
//             readOnly: emailVerified,
//           ),
//           ElevatedButton(
//             onPressed: emailVerified ? null : verifyEmail,
//             child: const Text('이메일 인증'),
//           ),
//           Text(emailStatus, style: TextStyle(color: emailVerified ? Colors.blue : Colors.red)),
//
//           const SizedBox(height: 8,),
//           TextField(
//             controller: pwCtrl,
//             decoration: const InputDecoration(labelText: '비밀번호'),
//             obscureText: true,
//           ),
//
//           const SizedBox(height: 8),
//           TextField(
//             controller: usernameCtrl,
//             decoration: const InputDecoration(labelText: '이름'),
//           ),
//
//           const SizedBox(height: 8),
//           TextField(
//             controller: nicknameCtrl,
//             decoration: const InputDecoration(labelText: '닉네임'),
//             onChanged: (_) {
//               setState(() {
//                 nicknameChecked = false;
//                 nicknameStatus = '중복 확인 필요';
//               });
//             },
//           ),
//           ElevatedButton(
//             onPressed: checkNickname,
//             child: const Text('닉네임 중복 확인'),
//           ),
//           Text(nicknameStatus, style: TextStyle(color: nicknameChecked ? Colors.blue : Colors.red)),
//
//           const SizedBox(height: 8),
//           TextField(
//             controller: profileImgCtrl,
//             decoration: const InputDecoration(labelText: '프로필 이미지 URL'),
//           ),
//
//           const SizedBox(height: 8),
//           TextField(
//             controller: phoneCtrl,
//             keyboardType: TextInputType.phone,
//             decoration: const InputDecoration(labelText: '전화번호'),
//             onChanged: formatPhone,
//           ),
//
//           const SizedBox(height: 8),
//           ListTile(
//             title: Text(
//               birthday == null
//                   ? '생년월일 선택'
//                   : '생년월일: ${birthday!.toLocal().toString().split(' ')[0]}',
//             ),
//             trailing: IconButton(
//               icon: const Icon(Icons.calendar_today),
//               onPressed: () async {
//                 final picked = await showDatePicker(
//                   context: context,
//                   initialDate: DateTime(2000),
//                   firstDate: DateTime(1900),
//                   lastDate: DateTime.now(),
//                 );
//                 if (picked != null) {
//                   setState(() => birthday = picked);
//                 }
//               },
//             ),
//           ),
//
//
//           const SizedBox(height: 16,),
//           FilledButton(
//             onPressed: loading ? null : _submit,
//             child: loading
//                 ? const CircularProgressIndicator()
//                 : const Text('가입하기'),
//           ),
//         ],
//       ),
//     );
//   }
// }