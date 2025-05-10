class NguoiDung {
  final String maNguoiDung;
  final String tenDangNhap;
  final String matKhau;
  final String email;
  final String? anhDaiDien;
  final DateTime ngayTao;
  final DateTime lanHoatDongCuoi;
  final String vaiTro; // Thêm trường vaiTro: "admin" hoặc "user"

  NguoiDung({
    required this.maNguoiDung,
    required this.tenDangNhap,
    required this.matKhau,
    required this.email,
    this.anhDaiDien,
    required this.ngayTao,
    required this.lanHoatDongCuoi,
    required this.vaiTro,
  });

  // Chuyển NguoiDung thành Map cho SQLite
  Map<String, dynamic> chuyenThanhMap() {
    return {
      'id': maNguoiDung,
      'username': tenDangNhap,
      'password': matKhau,
      'email': email,
      'avatar': anhDaiDien,
      'createdAt': ngayTao.toIso8601String(),
      'lastActive': lanHoatDongCuoi.toIso8601String(),
      'role': vaiTro,
    };
  }

  // Tạo NguoiDung từ Map (cho việc truy xuất SQLite)
  factory NguoiDung.tuMap(Map<String, dynamic> map) {
    return NguoiDung(
      maNguoiDung: map['id'],
      tenDangNhap: map['username'],
      matKhau: map['password'],
      email: map['email'],
      anhDaiDien: map['avatar'],
      ngayTao: DateTime.parse(map['createdAt']),
      lanHoatDongCuoi: DateTime.parse(map['lastActive']),
      vaiTro: map['role'],
    );
  }
}