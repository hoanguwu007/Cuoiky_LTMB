class CongViec {
  final String maCongViec;
  final String tieuDe;
  final String moTa;
  final String trangThai; // Cần làm, Đang làm, Hoàn thành, Đã hủy
  final int doUuTien; // 1: Thấp, 2: Trung bình, 3: Cao
  final DateTime? hanHoanThanh;
  final DateTime ngayTao;
  final DateTime ngayCapNhat;
  final String? nguoiDuocGiao; // User ID
  final String nguoiTao; // User ID
  final String? danhMuc;
  final List<String>? tepDinhKem;
  final bool daHoanThanh;

  CongViec({
    required this.maCongViec,
    required this.tieuDe,
    required this.moTa,
    required this.trangThai,
    required this.doUuTien,
    this.hanHoanThanh,
    required this.ngayTao,
    required this.ngayCapNhat,
    this.nguoiDuocGiao,
    required this.nguoiTao,
    this.danhMuc,
    this.tepDinhKem,
    required this.daHoanThanh,
  });

  // Chuyển CongViec thành Map cho SQLite
  Map<String, dynamic> chuyenThanhMap() {
    return {
      'id': maCongViec,
      'title': tieuDe,
      'description': moTa,
      'status': trangThai,
      'priority': doUuTien,
      'dueDate': hanHoanThanh?.toIso8601String(),
      'createdAt': ngayTao.toIso8601String(),
      'updatedAt': ngayCapNhat.toIso8601String(),
      'assignedTo': nguoiDuocGiao,
      'createdBy': nguoiTao,
      'category': danhMuc,
      'attachments': tepDinhKem?.join(','), // Lưu dưới dạng chuỗi phân cách bằng dấu phẩy
      'completed': daHoanThanh ? 1 : 0,
    };
  }

  // Tạo CongViec từ Map (cho việc truy xuất SQLite)
  factory CongViec.tuMap(Map<String, dynamic> map) {
    return CongViec(
      maCongViec: map['id'],
      tieuDe: map['title'],
      moTa: map['description'],
      trangThai: map['status'],
      doUuTien: map['priority'],
      hanHoanThanh: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      ngayTao: DateTime.parse(map['createdAt']),
      ngayCapNhat: DateTime.parse(map['updatedAt']),
      nguoiDuocGiao: map['assignedTo'],
      nguoiTao: map['createdBy'],
      danhMuc: map['category'],
      tepDinhKem: map['attachments'] != null
          ? (map['attachments'] as String).split(',')
          : null,
      daHoanThanh: map['completed'] == 1,
    );
  }
}