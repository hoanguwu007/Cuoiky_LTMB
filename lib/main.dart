import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'CKTask/view/login_view.dart';
import 'CKTask/view/home_view.dart';
import 'package:app_03/CKTask/service/user_service.dart';
import 'package:app_03/CKTask/service/DatabaseHelper.dart';
import 'package:app_03/CKTask/model/user_model.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await _khoiTaoFirebase();
  await _capNhatVaiTroAdmin();
  runApp(const MyApp());
}

Future<void> _khoiTaoFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> _capNhatVaiTroAdmin() async {
  final dbService = DatabaseService();
  final adminEmail = 'vuthuy1159@gmail.com';
  final users = await dbService.layDanhSachNguoiDung(); // Lấy danh sách tất cả người dùng từ cơ sở dữ liệu

  for (var user in users) {
    if (user.email == adminEmail) { // Kiểm tra nếu email của người dùng là email admin
      if (user.vaiTro != 'admin') { // Kiểm tra nếu vai trò của người dùng không phải là admin
        final updatedUser = NguoiDung( // Tạo đối tượng người dùng mới với vai trò admin
          maNguoiDung: user.maNguoiDung,
          tenDangNhap: user.tenDangNhap,
          matKhau: user.matKhau,
          email: user.email,
          anhDaiDien: user.anhDaiDien,
          ngayTao: user.ngayTao,
          lanHoatDongCuoi: user.lanHoatDongCuoi,
          vaiTro: 'admin',
        );
        await dbService.capNhatNguoiDung(updatedUser);
        print('Đã cập nhật vai trò Admin cho $adminEmail');
      }
    } else { // Nếu không phải tài khoản admin

      if (user.vaiTro != 'user') { // Kiểm tra nếu vai trò không phải là user
        final updatedUser = NguoiDung( // Tạo đối tượng người dùng mới với vai trò user
          maNguoiDung: user.maNguoiDung,
          tenDangNhap: user.tenDangNhap,
          matKhau: user.matKhau,
          email: user.email,
          anhDaiDien: user.anhDaiDien,
          ngayTao: user.ngayTao,
          lanHoatDongCuoi: user.lanHoatDongCuoi,
          vaiTro: 'user', // Cập nhật vai trò thành user
        );
        await dbService.capNhatNguoiDung(updatedUser);
        print('Đã cập nhật vai trò User cho ${user.email}');
      }
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _kiemTraTrangThaiDangNhap(),
    );
  }

  Widget _kiemTraTrangThaiDangNhap() {
    return StreamBuilder<NguoiDung?>(
      stream: AuthService().theoDoiTrangThaiDangNhap,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Hiển thị vòng tròn loading
        }
        if (snapshot.hasData && snapshot.data != null) { // Nếu có dữ liệu và người dùng đã đăng nhập
          return const HomeView(); // Hiển thị HomeView
        }
        return const LoginView(); // Nếu chưa đăng nhập, hiển thị màn hình đăng nhập
      },
    );
  }
}