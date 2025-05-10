import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/task_model.dart';
import '../service/DatabaseHelper.dart';
import 'task_form_view.dart';

class TaskDetailView extends StatefulWidget {
  final CongViec task;

  const TaskDetailView({super.key, required this.task});

  @override
  _TaskDetailViewState createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late CongViec _task;
  final DatabaseService _databaseService = DatabaseService();
  bool _isAssignedUserDeleted = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    kiemTraNguoiDuocGiao();
  }

  // Kiểm tra xem người được gán công việc có còn tồn tại hay không
  Future<void> kiemTraNguoiDuocGiao() async {
    if (_task.nguoiDuocGiao != null) {
      final user = await _databaseService.layNguoiDung(_task.nguoiDuocGiao!);
      setState(() {
        _isAssignedUserDeleted = user == null;
      });
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

  void chuyenDenSuaCongViec() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormView(task: _task),
      ),
    ).then((result) {
      if (result != null && result is CongViec) {
        setState(() {
          _task = result;
        });
        Navigator.pop(context, result);
      }
    });
  }

  Future<String> layTenNguoiDung(String? userId) async {
    if (userId == null) return 'Không có';
    final tenDangNhap = await _databaseService.layTenDangNhap(userId);
    return tenDangNhap ?? 'Người dùng đã bị xóa';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_task.tieuDe, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isAssignedUserDeleted ? null : chuyenDenSuaCongViec,
            tooltip: _isAssignedUserDeleted ? 'Không thể chỉnh sửa vì người được gán đã bị xóa' : 'Chỉnh sửa công việc',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Mô tả', _task.moTa),
                  const Divider(),
                  _buildInfoRow('Trạng thái', _task.trangThai),
                  _buildInfoRowWidget('Ưu tiên', layVanBanDoUuTien(_task.doUuTien)),
                  _buildInfoRow(
                    'Hạn hoàn thành',
                    _task.hanHoanThanh != null
                        ? DateFormat('dd-MM-yyyy').format(_task.hanHoanThanh!)
                        : 'Không có',
                  ),
                  FutureBuilder<String>(
                    future: layTenNguoiDung(_task.nguoiTao),
                    builder: (context, snapshot) {
                      return _buildInfoRow('Được tạo bởi', snapshot.data ?? 'Đang tải...');
                    },
                  ),
                  FutureBuilder<String>(
                    future: layTenNguoiDung(_task.nguoiDuocGiao),
                    builder: (context, snapshot) {
                      return _buildInfoRow('Giao cho', snapshot.data ?? 'Đang tải...');
                    },
                  ),
                  _buildInfoRow('Danh mục', _task.danhMuc ?? 'Không có'),
                  _buildInfoRow('Hoàn thành', _task.daHoanThanh ? 'Có' : 'Không'),
                  _buildInfoRow(
                    'Cập nhật lần cuối',
                    DateFormat('dd-MM-yyyy HH:mm').format(_task.ngayCapNhat),
                  ),
                  if (_task.tepDinhKem != null && _task.tepDinhKem!.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      'Tệp đính kèm:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ..._task.tepDinhKem!.map(
                          (attachment) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(attachment, style: const TextStyle(color: Colors.blue)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWidget(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: value,
          ),
        ],
      ),
    );
  }
}