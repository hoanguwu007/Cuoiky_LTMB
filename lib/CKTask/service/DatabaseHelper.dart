import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/user_model.dart';
import '../model/task_model.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'task_manager.db';
  static const String _userTable = 'users';
  static const String _taskTable = 'tasks';

  // Lấy hoặc khởi tạo cơ sở dữ liệu
  Future<Database> get layCSDL async {
    if (_database != null) return _database!;
    _database = await khoiTaoCSDL();
    return _database!;
  }

  // Khởi tạo cơ sở dữ liệu và tạo bảng nếu chưa tồn tại
  Future<Database> khoiTaoCSDL() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tạo bảng users với các cột thông tin người dùng
        await db.execute('''
          CREATE TABLE $_userTable (
            id TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            email TEXT NOT NULL,
            avatar TEXT,
            createdAt TEXT NOT NULL,
            lastActive TEXT NOT NULL,
            role TEXT NOT NULL
          )
        ''');

        // Tạo bảng tasks với các cột thông tin công việc
        await db.execute('''
          CREATE TABLE $_taskTable (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            status TEXT NOT NULL,
            priority INTEGER NOT NULL,
            dueDate TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            assignedTo TEXT,
            createdBy TEXT NOT NULL,
            category TEXT,
            attachments TEXT,
            completed INTEGER NOT NULL,
            FOREIGN KEY (assignedTo) REFERENCES $_userTable(id),
            FOREIGN KEY (createdBy) REFERENCES $_userTable(id)
          )
        ''');

        // Tạo các index để tối ưu hóa truy vấn theo trạng thái và danh mục
        await db.execute('CREATE INDEX idx_tasks_status ON $_taskTable(status)');
        await db.execute('CREATE INDEX idx_tasks_category ON $_taskTable(category)');
      },
    );
  }

  // CRUD cho NguoiDung
  // Thêm người dùng mới vào cơ sở dữ liệu
  Future<void> themNguoiDung(NguoiDung user) async {
    final db = await layCSDL;
    final userMap = user.chuyenThanhMap();
    if (userMap['role'] == null || userMap['role'].isEmpty) {
      throw Exception('Vai trò không được để trống khi thêm người dùng');
    }
    await db.insert(_userTable, userMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Lấy thông tin người dùng theo ID
  Future<NguoiDung?> layNguoiDung(String id) async {
    final db = await layCSDL;
    final maps = await db.query(
      _userTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return NguoiDung.tuMap(maps.first);
    }
    return null;
  }

  // Lấy tên đăng nhập từ ID người dùng
  Future<String?> layTenDangNhap(String id) async {
    final user = await layNguoiDung(id);
    return user?.tenDangNhap;
  }

  // Lấy danh sách tất cả người dùng
  Future<List<NguoiDung>> layDanhSachNguoiDung() async {
    final db = await layCSDL;
    final maps = await db.query(_userTable);
    return maps.map((map) => NguoiDung.tuMap(map)).toList();
  }

  // Cập nhật thông tin người dùng
  Future<void> capNhatNguoiDung(NguoiDung user) async {
    final db = await layCSDL;
    await db.update(
      _userTable,
      user.chuyenThanhMap(),
      where: 'id = ?',
      whereArgs: [user.maNguoiDung],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Xóa người dùng khỏi cơ sở dữ liệu
  Future<void> xoaNguoiDung(String id) async {
    final db = await layCSDL;
    await db.delete(
      _userTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Kiểm tra trạng thái hoàn thành của công việc của người dùng
  Future<bool> kiemTraTrangThaiCongViecNguoiDung(String userId) async {
    final db = await layCSDL;
    final maps = await db.query(
      _taskTable,
      where: 'assignedTo = ? AND completed != ?',
      whereArgs: [userId, 1],
    );
    return maps.isEmpty; // Trả về true nếu không có công việc nào chưa hoàn thành
  }

  // Thêm công việc mới vào cơ sở dữ liệu
  Future<void> themCongViec(CongViec task) async {
    final db = await layCSDL;
    await db.insert(_taskTable, task.chuyenThanhMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Lấy danh sách tất cả công việc
  Future<List<CongViec>> layDanhSachCongViec() async {
    final db = await layCSDL;
    final maps = await db.query(_taskTable);
    return maps.map((map) => CongViec.tuMap(map)).toList();
  }

  // Lấy thông tin công việc theo ID
  Future<CongViec?> layCongViec(String id) async {
    final db = await layCSDL;
    final maps = await db.query(
      _taskTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CongViec.tuMap(maps.first);
    }
    return null;
  }

  // Cập nhật thông tin công việc
  Future<void> capNhatCongViec(CongViec task) async {
    final db = await layCSDL;
    await db.update(
      _taskTable,
      task.chuyenThanhMap(),
      where: 'id = ?',
      whereArgs: [task.maCongViec],
    );
  }

  // Xóa công việc khỏi cơ sở dữ liệu
  Future<void> xoaCongViec(String id) async {
    final db = await layCSDL;
    await db.delete(
      _taskTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tìm kiếm và lọc danh sách công việc theo tiêu chí
  Future<List<CongViec>> timKiemCongViec({
    String? keyword,
    String? status,
    String? category,
    String? assignedTo,
    required String currentUserId,
    required String userRole,
  }) async {
    final db = await layCSDL;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (userRole != 'admin') {
      // Tài khoản thông thường chỉ thấy công việc được gán cho họ
      whereClauses.add('assignedTo = ?');
      whereArgs.add(currentUserId);
    }

    if (keyword != null && keyword.isNotEmpty) {
      whereClauses.add('title LIKE ? OR description LIKE ?');
      whereArgs.addAll(['%$keyword%', '%$keyword%']);
    }
    if (status != null && status.isNotEmpty) {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }
    if (category != null && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }
    if (assignedTo != null && assignedTo.isNotEmpty && userRole == 'admin') {
      whereClauses.add('assignedTo = ?');
      whereArgs.add(assignedTo);
    }

    final maps = await db.query(
      _taskTable,
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps.map((map) => CongViec.tuMap(map)).toList();
  }
}