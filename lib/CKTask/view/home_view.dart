import 'package:flutter/material.dart';
import '../service/user_service.dart';
import '../service/DatabaseHelper.dart';
import '../model/task_model.dart';
import 'login_view.dart';
import 'task_detail_view.dart';
import 'task_form_view.dart';
import 'user_management_view.dart'; // Thêm import cho màn hình quản lý người dùng

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  List<CongViec> _tasks = [];
  String _filterStatus = '';
  String _searchQuery = '';
  bool _isGridView = false;
  String? _currentUserId;
  String? _currentUserRole;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    taiDuLieuBanDau();
    hienThongBaoDangNhapThanhCong();
  }

  Future<void> taiDuLieuBanDau() async {
    final currentUser = await _authService.theoDoiTrangThaiDangNhap.first;
    setState(() {
      _currentUserId = currentUser?.maNguoiDung;
      _currentUsername = currentUser?.tenDangNhap;
    });
    if (_currentUserId != null) {
      final user = await _databaseService.layNguoiDung(_currentUserId!);
      setState(() {
        _currentUserRole = user?.vaiTro ?? 'user';
      });
      taiCongViec();
    }
  }

  void hienThongBaoDangNhapThanhCong() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công!'),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  Future<void> taiCongViec() async {
    if (_currentUserId == null || _currentUserRole == null) return;
    final tasks = await _databaseService.timKiemCongViec(
      keyword: _searchQuery,
      status: _filterStatus.isNotEmpty ? _filterStatus : null,
      currentUserId: _currentUserId!,
      userRole: _currentUserRole!,
    );
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> hienHopThoaiDangXuat() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.dangXuat();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng xuất thành công!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  Widget layVanBanDoUuTien(int priority) {
    String text;
    Color color;
    switch (priority) {
      case 1:
        text = 'Thấp';
        color = Colors.green;
        break;
      case 2:
        text = 'Trung bình';
        color = Colors.yellow.shade700;
        break;
      case 3:
        text = 'Cao';
        color = Colors.red;
        break;
      default:
        text = 'Không xác định';
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> xoaCongViec(String taskId, String taskTitle) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa công việc "$taskTitle"?'),
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
      await _databaseService.xoaCongViec(taskId);
      taiCongViec();
    }
  }

  Future<String> layTenNguoiDung(String? userId) async {
    if (userId == null) return 'Không có';
    final tenDangNhap = await _databaseService.layTenDangNhap(userId);
    return tenDangNhap ?? userId;
  }

  Widget xayDungMucCongViec(CongViec task, {bool isGrid = false}) {
    return FutureBuilder(
      future: Future.wait([
        layTenNguoiDung(task.nguoiDuocGiao),
        layTenNguoiDung(task.nguoiTao),
      ]),
      builder: (context, AsyncSnapshot<List<String>> snapshot) {
        final assignedTo = snapshot.data?[0] ?? 'Không có';
        final createdBy = snapshot.data?[1] ?? 'Không xác định';
        return isGrid // Kiểm tra chế độ hiển thị
            ? Card( // Nếu là lưới, hiển thị dạng thẻ
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.tieuDe,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Trạng thái: ${task.trangThai}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    const Text(
                      'Ưu tiên: ',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    layVanBanDoUuTien(task.doUuTien),
                  ],
                ),
                Text(
                  'Giao cho: $assignedTo',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        task.daHoanThanh ? Icons.check_circle : Icons.circle_outlined,
                        color: task.daHoanThanh ? Colors.green : Colors.grey,
                      ),
                      onPressed: () async {
                        await _databaseService.capNhatCongViec(
                          CongViec(
                            maCongViec: task.maCongViec,
                            tieuDe: task.tieuDe,
                            moTa: task.moTa,
                            trangThai: task.trangThai,
                            doUuTien: task.doUuTien,
                            hanHoanThanh: task.hanHoanThanh,
                            ngayTao: task.ngayTao,
                            ngayCapNhat: DateTime.now(),
                            nguoiDuocGiao: task.nguoiDuocGiao,
                            nguoiTao: task.nguoiTao,
                            danhMuc: task.danhMuc,
                            tepDinhKem: task.tepDinhKem,
                            daHoanThanh: !task.daHoanThanh,
                          ),
                        );
                        taiCongViec();
                      },
                    ),
                    IconButton(//nút xóa dạng list
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await xoaCongViec(task.maCongViec, task.tieuDe);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
            : Card( // Nếu là danh sách, hiển thị dạng List
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile( //Chế độ danh sách
            contentPadding: const EdgeInsets.all(12),
            title: Text(task.tieuDe, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trạng thái: ${task.trangThai}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    const Text(
                      'Ưu tiên: ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    layVanBanDoUuTien(task.doUuTien),
                  ],
                ),
                Text(
                  'Giao cho: $assignedTo',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    task.daHoanThanh ? Icons.check_circle : Icons.circle_outlined,
                    color: task.daHoanThanh ? Colors.green : Colors.grey,
                  ),
                  onPressed: () async {
                    await _databaseService.capNhatCongViec(
                      CongViec(
                        maCongViec: task.maCongViec,
                        tieuDe: task.tieuDe,
                        moTa: task.moTa,
                        trangThai: task.trangThai,
                        doUuTien: task.doUuTien,
                        hanHoanThanh: task.hanHoanThanh,
                        ngayTao: task.ngayTao,
                        ngayCapNhat: DateTime.now(),
                        nguoiDuocGiao: task.nguoiDuocGiao,
                        nguoiTao: task.nguoiTao,
                        danhMuc: task.danhMuc,
                        tepDinhKem: task.tepDinhKem,
                        daHoanThanh: !task.daHoanThanh,
                      ),
                    );
                    taiCongViec();
                  },
                ),
                IconButton( //nút xóa dạng lưới
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await xoaCongViec(task.maCongViec, task.tieuDe);
                  },
                ),
              ],
            ),
            onTap: () {// Sự kiện khi nhấn vào công việc
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailView(task: task),
                ),
              ).then((result) {
                if (result != null) {
                  taiCongViec();
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildAdminDashboard() {
    final completedTasks = _tasks.where((task) => task.daHoanThanh).length;
    return Column(
      children: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng công việc: ${_tasks.length}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Hoàn thành: $completedTasks',
                      style: const TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserManagementView()),
                    );
                  },
                  icon: const Icon(Icons.people, color: Colors.white),
                  label: const Text('Quản lý người dùng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Xin chào, ${_currentUsername ?? 'Người dùng'}!',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUserRole == 'admin';
    return Theme(
      data: isAdmin
          ? ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.blue.shade50,
        cardColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
          ),
        ),
      )
          : ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey.shade100,
        cardColor: Colors.teal.shade50,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAdmin ? 'Bảng điều khiển Admin' : 'Công việc của bạn'),
          backgroundColor: isAdmin ? Colors.blue.shade900 : Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
              tooltip: _isGridView ? 'Chuyển sang danh sách' : 'Chuyển sang lưới',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: hienHopThoaiDangXuat,
              tooltip: 'Đăng xuất',
            ),
          ],
        ),
        body: Column(
          children: [
            if (isAdmin) _buildAdminDashboard() else _buildUserHeader(),
            Card(
              elevation: 2,
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm',
                    prefixIcon: Icon(Icons.search, color: isAdmin ? Colors.blue.shade900 : Colors.teal),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    taiCongViec();
                  },
                ),
              ),
            ),
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Lọc theo trạng thái',
                    border: InputBorder.none,
                  ),
                  value: _filterStatus.isEmpty ? null : _filterStatus,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'Cần làm', child: Text('Cần làm')),
                    DropdownMenuItem(value: 'Đang làm', child: Text('Đang làm')),
                    DropdownMenuItem(value: 'Hoàn thành', child: Text('Hoàn thành')),
                    DropdownMenuItem(value: 'Đã hủy', child: Text('Đã hủy')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value ?? '';
                    });
                    taiCongViec();
                  },
                ),
              ),
            ),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(child: Text('Không có công việc nào.', style: TextStyle(fontSize: 16)))
                  : _isGridView// Kiểm tra chế độ hiển thị
                  ? GridView.builder(// Nếu là lưới, sử dụng GridView
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(// Cấu hình lưới
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                ),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return GestureDetector( //Chế độ lưới
                    onTap: () {// Sự kiện khi nhấn vào công việc
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailView(task: task),
                        ),
                      ).then((result) {
                        if (result != null) {
                          taiCongViec();
                        }
                      });
                    },
                    child: xayDungMucCongViec(task, isGrid: true),
                  );
                },
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return xayDungMucCongViec(task);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TaskFormView(),
              ),
            ).then((result) {
              if (result != null) {
                taiCongViec();
              }
            });
          },
          backgroundColor: isAdmin ? Colors.blue.shade900 : Colors.teal,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}