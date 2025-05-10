import 'package:flutter/material.dart';
import '../model/user_model.dart';
import '../service/DatabaseHelper.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  _UserManagementViewState createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final DatabaseService _databaseService = DatabaseService();
  List<NguoiDung> _users = [];

  @override
  void initState() {
    super.initState();
    taiDanhSachNguoiDung();
  }

  Future<void> taiDanhSachNguoiDung() async {
    final users = await _databaseService.layDanhSachNguoiDung();
    setState(() {
      _users = users;
    });
  }

  Future<void> xoaNguoiDung(String userId, String username, String vaiTro) async {
    // Kiểm tra nếu người dùng là Admin
    if (vaiTro == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa tài khoản Admin!')),
      );
      return;
    }

    // Kiểm tra trạng thái hoàn thành của công việc của người dùng
    final tatCaCongViecHoanThanh = await _databaseService.kiemTraTrangThaiCongViecNguoiDung(userId);
    if (!tatCaCongViecHoanThanh) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ có thể xóa người dùng khi tất cả công việc của họ được đánh dấu hoàn thành!')),
      );
      return;
    }

    // Hiển thị hộp thoại xác nhận xóa
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa người dùng "$username"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _databaseService.xoaNguoiDung(userId);
      taiDanhSachNguoiDung();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa người dùng thành công!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.blue.shade50,
        child: _users.isEmpty
            ? const Center(child: Text('Không có người dùng nào.', style: TextStyle(fontSize: 16)))
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.anhDaiDien != null ? NetworkImage(user.anhDaiDien!) : null,
                  child: user.anhDaiDien == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user.tenDangNhap, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${user.email}'),
                    Text('Vai trò: ${user.vaiTro}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await xoaNguoiDung(user.maNguoiDung, user.tenDangNhap, user.vaiTro);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}