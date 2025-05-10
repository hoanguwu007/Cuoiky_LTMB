import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../model/task_model.dart';
import '../model/user_model.dart';
import '../service/DatabaseHelper.dart';
import '../service/user_service.dart';

class TaskFormView extends StatefulWidget {
  final CongViec? task;

  const TaskFormView({super.key, this.task});

  @override
  _TaskFormViewState createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<TaskFormView> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _attachmentController;
  String _status = 'Cần làm';
  int _priority = 1;
  DateTime? _dueDate;
  List<String> _attachments = [];
  String? _assignedTo;
  String? _category;
  List<NguoiDung> _users = [];
  final List<String> _categories = ['Công việc cá nhân', 'Công việc nhóm', 'Dự án', 'Khác'];
  String? _currentUserId;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.tieuDe ?? '');
    _descriptionController = TextEditingController(text: widget.task?.moTa ?? '');
    _attachmentController = TextEditingController();
    _status = widget.task?.trangThai ?? 'Cần làm';
    _priority = widget.task?.doUuTien ?? 1;
    _dueDate = widget.task?.hanHoanThanh;
    _attachments = widget.task?.tepDinhKem ?? [];
    _assignedTo = widget.task?.nguoiDuocGiao;
    _category = widget.task?.danhMuc;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await taiDuLieuBanDau();
    });
  }

  Future<void> taiDuLieuBanDau() async {
    final currentUser = await _authService.theoDoiTrangThaiDangNhap.first;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lấy thông tin người dùng hiện tại')),
      );
      return;
    }
    final users = await _databaseService.layDanhSachNguoiDung();
    final currentUserData = await _databaseService.layNguoiDung(currentUser.maNguoiDung);
    setState(() {
      _currentUserId = currentUser.maNguoiDung;
      _currentUserRole = currentUserData?.vaiTro ?? 'user';
      _users = users;
      if (_currentUserRole != 'admin' && _assignedTo == null) {
        _assignedTo = _currentUserId;
      }
    });
  }

  Future<void> chonHanHoanThanh(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void themLinkTaiLieu() {
    final link = _attachmentController.text.trim();
    if (link.isNotEmpty && Uri.tryParse(link)?.hasAbsolutePath == true) {
      setState(() {
        _attachments.add(link);
        _attachmentController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập URL hợp lệ')),
      );
    }
  }

  void xoaLinkTaiLieu(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> luuCongViec() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xác định người tạo công việc')),
        );
        return;
      }

      if (_currentUserRole != 'admin' && _assignedTo == null) {
        _assignedTo = _currentUserId;
      }

      final currentUserExists = await _databaseService.layNguoiDung(_currentUserId!);
      if (currentUserExists == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Người tạo công việc không tồn tại trong hệ thống')),
        );
        return;
      }

      if (_assignedTo != null) {
        final assignedUser = await _databaseService.layNguoiDung(_assignedTo!);
        if (assignedUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Người được gán không tồn tại trong hệ thống')),
          );
          return;
        }
      }

      try {
        final task = CongViec(
          maCongViec: widget.task?.maCongViec ?? const Uuid().v4(),
          tieuDe: _titleController.text.trim(),
          moTa: _descriptionController.text.trim(),
          trangThai: _status,
          doUuTien: _priority,
          hanHoanThanh: _dueDate,
          ngayTao: widget.task?.ngayTao ?? DateTime.now(),
          ngayCapNhat: DateTime.now(),
          nguoiDuocGiao: _assignedTo,
          nguoiTao: _currentUserId!,
          danhMuc: _category,
          tepDinhKem: _attachments.isNotEmpty ? _attachments : null,
          daHoanThanh: widget.task?.daHoanThanh ?? false,
        );

        if (widget.task == null) {
          await _databaseService.themCongViec(task);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm công việc thành công!')),
          );
        } else {
          await _databaseService.capNhatCongViec(task);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật công việc thành công!')),
          );
        }

        Navigator.pop(context, task);
      } catch (e) {
        print('Lỗi khi lưu công việc: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra lại thông tin nhập')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _attachmentController.dispose();
    super.dispose();
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
          title: Text(widget.task == null ? 'Thêm công việc' : 'Sửa công việc'),
          backgroundColor: isAdmin ? Colors.blue.shade900 : Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          color: isAdmin ? Colors.blue.shade50 : Colors.grey.shade100,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: isAdmin ? Colors.blue.shade50 : Colors.teal.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: isAdmin ? Colors.blue.shade50 : Colors.teal.shade50,
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mô tả';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: isAdmin ? Colors.blue.shade50 : Colors.teal.shade50,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cần làm', child: Text('Cần làm')),
                          DropdownMenuItem(value: 'Đang làm', child: Text('Đang làm')),
                          DropdownMenuItem(value: 'Hoàn thành', child: Text('Hoàn thành')),
                          DropdownMenuItem(value: 'Đã hủy', child: Text('Đã hủy')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: 'Độ ưu tiên',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: isAdmin ? Colors.blue.shade50 : Colors.teal.shade50,
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Thấp')),
                          DropdownMenuItem(value: 2, child: Text('Trung bình')),
                          DropdownMenuItem(value: 3, child: Text('Cao')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _priority = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _assignedTo,
                        decoration: InputDecoration(
                          labelText: 'Giao cho',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: isAdmin ? Colors.blue.shade50 : Colors.teal.shade50,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Không có'),
                          ),
                          ...(_currentUserRole == 'admin'
                              ? _users
                              : _users.where((user) => user.maNguoiDung == _currentUserId))
                              .map((user) => DropdownMenuItem<String>(
                            value: user.maNguoiDung,
                            child: Text(user.tenDangNhap),
                          )),
                        ],
                        onChanged: _currentUserRole == 'admin' || _users.isEmpty
                            ? (value) {
                          setState(() {
                            _assignedTo = value;
                          });
                        }
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Danh mục (tùy chọn)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: isAdmin ? Colors.blue.shade50 : Colors.teal.shade50,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Không có'),
                          ),
                          ..._categories.map((category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _category = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          title: Text(
                            'Hạn hoàn thành: ${_dueDate != null ? DateFormat('dd-MM-yyyy').format(_dueDate!) : 'Chưa chọn'}',
                          ),
                          trailing: Icon(Icons.calendar_today, color: isAdmin ? Colors.blue.shade900 : Colors.teal),
                          onTap: () => chonHanHoanThanh(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _attachmentController,
                        decoration: InputDecoration(
                          labelText: 'Thêm link tài liệu (tùy chọn)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: isAdmin ? Colors.blue.shade50 : Colors.teal.shade50,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.add, color: isAdmin ? Colors.blue.shade900 : Colors.teal),
                            onPressed: themLinkTaiLieu,
                          ),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                      if (_attachments.isNotEmpty) ...[
                        const Text(
                          'Tài liệu đính kèm:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _attachments.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _attachments[index],
                                style: const TextStyle(color: Colors.blue),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => xoaLinkTaiLieu(index),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: luuCongViec,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          widget.task == null ? 'Thêm' : 'Cập nhật',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}