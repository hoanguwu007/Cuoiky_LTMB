import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/user_model.dart';
import 'DatabaseHelper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseService _databaseService = DatabaseService();

  // Tạo đối tượng NguoiDung từ User của Firebase
  NguoiDung? taoNguoiDungTuUser(User? user, {String? role}) { // Hàm tạo NguoiDung từ User của Firebase
    if (user == null) return null;

    return NguoiDung(
      maNguoiDung: user.uid, // Mã người dùng lấy từ UID của Firebase
      tenDangNhap: user.displayName ?? user.email?.split('@')[0] ?? 'user_${user.uid}', // Tên đăng nhập lấy từ displayName hoặc email, nếu không có thì tạo mặc định
      matKhau: '', // Mật khẩu để trống (Firebase quản lý mật khẩu)
      email: user.email ?? '',
      anhDaiDien: user.photoURL,
      ngayTao: user.metadata.creationTime ?? DateTime.now(),
      lanHoatDongCuoi: user.metadata.lastSignInTime ?? DateTime.now(),
      vaiTro: role ?? '', // Vai trò được truyền vào hoặc để trống
    );
  }

  // Theo dõi trạng thái đăng nhập của người dùng
  Stream<NguoiDung?> get theoDoiTrangThaiDangNhap {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null; // Nếu người dùng đăng xuất, trả về null
      final nguoiDung = await _databaseService.layNguoiDung(user.uid);
      return nguoiDung; // nếu người dùng đã đăng nhập, trả về đối tượng NguoiDung
    });
  }

  // Đăng ký tài khoản mới bằng email và mật khẩu
  Future<NguoiDung?> dangKyVoiEmailVaMatKhau(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      final role = email == 'vuthuy1159@gmail.com' ? 'admin' : 'user'; // Gán vai trò admin nếu email là vuthuy1159@gmail.com, ngược lại là user
      final nguoiDung = taoNguoiDungTuUser(user, role: role);
      if (nguoiDung != null) {
        await _databaseService.themNguoiDung(nguoiDung);
      }
      return nguoiDung;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Đăng nhập bằng email và mật khẩu
  Future<NguoiDung?> dangNhapVoiEmailVaMatKhau(String email, String password) async {
    try {//Nếu thành công, Firebase trả về đối tượng UserCredential chứa thông tin người dùng user
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      final nguoiDung = await _databaseService.layNguoiDung(user!.uid);
      return nguoiDung;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Đăng nhập bằng tài khoản Google
  Future<NguoiDung?> dangNhapVoiGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      //Thông tin xác thực  được gửi đến Firebase để đăng nhập
      final UserCredential result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return null;

      // Kiểm tra xem người dùng đã tồn tại trong cơ sở dữ liệu chưa
      final existingUser = await _databaseService.layNguoiDung(user.uid);
      if (existingUser == null) {
        final role = user.email == 'vuthuy1159@gmail.com' ? 'admin' : 'user';
        final nguoiDung = taoNguoiDungTuUser(user, role: role);
        if (nguoiDung != null) {
          await _databaseService.themNguoiDung(nguoiDung);
        }
        return nguoiDung;
      }
      return existingUser;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }



  // Đăng xuất người dùng
  Future<void> dangXuat() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print(e.toString());
    }
  }
}