import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Emulator Android: 10.0.2.2. HP fisik: ganti IP LAN komputer.
  // Saat rilis: gunakan URL HTTPS server, jangan localhost.
  static const String baseUrl = 'http://localhost/ayo_laundry_api'; // Flutter Web di PC
  static const _storage = FlutterSecureStorage();
  static String? nama;
  static String? email;
  static String? role;
  static String? alamat;
  static String? fotoUrl;
  static const String _rememberKey = 'ayo_remember_session';
  static bool _rememberMe = false;
  static String? _token;

  static Future<Map<String, dynamic>> _request(String path, Map<String, dynamic> body, {bool auth = false}) async {
    final token = _token ?? await _storage.read(key: 'auth_token');
    if (auth && (token == null || token.isEmpty)) throw Exception('Sesi habis. Silakan login ulang.');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$path'),
        headers: {
          'Content-Type': 'application/json',
          if (auth) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw Exception('Respons server tidak valid.');
      if (response.statusCode == 401) throw ApiUnauthorizedException();
      if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] != true) {
        throw Exception(decoded['message']?.toString() ?? 'Permintaan gagal.');
      }
      return decoded;
    } on FormatException {
      throw Exception('Server tidak mengembalikan JSON. Cek alamat API dan error PHP.');
    } on http.ClientException {
      throw Exception('Tidak bisa tersambung ke server. Cek XAMPP/IP.');
    }
  }

  static Future<void> register(String namaBaru, String emailBaru, String password) async {
    await _request('register.php', {'nama': namaBaru, 'email': emailBaru, 'password': password});
  }

  static void _setUser(Map user) {
    nama = user['nama']?.toString();
    email = user['email']?.toString();
    role = user['role']?.toString();
    alamat = user['alamat']?.toString();
    final photo = user['foto_profil']?.toString();
    if (photo == null || photo.isEmpty) {
      fotoUrl = null;
    } else if (Uri.tryParse(photo)?.hasScheme == true) {
      fotoUrl = photo;
    } else {
      fotoUrl = '$baseUrl/${photo.replaceFirst(RegExp(r'^/+'), '')}';
    }
  }

  static Future<void> login(String emailInput, String password,
      {bool rememberMe = false}) async {
    final data = await _request('login.php', {'email': emailInput, 'password': password});
    final token = data['token'];
    final user = data['user'];
    if (token is! String || user is! Map) throw Exception('Data login server tidak lengkap.');
    _token = token;
    _rememberMe = rememberMe;
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await _storage.write(key: 'auth_token', value: token);
      await prefs.setBool(_rememberKey, true);
    } else {
      await prefs.setBool(_rememberKey, false);
      await _storage.delete(key: 'auth_token');
    }
    _setUser(user);
    // Profil melengkapi alamat/foto meskipun login.php lama belum mengirimkannya.
    await refreshProfile();
  }

  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool(_rememberKey) ?? false;
    if (!_rememberMe) return false;
    try {
      _token = await _storage.read(key: 'auth_token');
      if (_token == null || _token!.isEmpty) return false;
      await refreshProfile();
      return true;
    } on ApiUnauthorizedException {
      await _storage.delete(key: 'auth_token');
      await prefs.setBool(_rememberKey, false);
      _token = null;
      return false;
    } catch (_) {
      // Gangguan koneksi server bukan bukti token kedaluwarsa.
      _token = null;
      return false;
    }
  }

  static Future<void> refreshProfile() async {
    final data = await _request('profile.php', {}, auth: true);
    final user = data['user'];
    if (user is! Map) throw Exception('Data profil tidak tersedia.');
    _setUser(user);
  }

  static Future<void> simpanAlamat(String alamatBaru) async {
    final result = await _request('update_address.php', {'alamat': alamatBaru}, auth: true);
    alamat = result['alamat']?.toString() ?? alamatBaru;
  }

  static Future<void> uploadFotoProfil(Uint8List bytes) async {
    if (bytes.length > 2 * 1024 * 1024) {
      throw Exception('Foto maksimal 2 MB. Pilih atau kompres gambar lebih kecil.');
    }
    final result = await _request('upload_profile.php', {
      'image_base64': base64Encode(bytes),
    }, auth: true);
    final photo = result['foto_profil']?.toString();
    if (photo == null || photo.isEmpty) throw Exception('Server tidak mengembalikan alamat foto.');
    fotoUrl = photo.startsWith('http://') || photo.startsWith('https://')
        ? photo
        : '$baseUrl/${photo.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static Future<void> ubahNama(String namaBaru) async {
    final data = await _request('edit_nama.php', {'nama': namaBaru}, auth: true);
    nama = data['nama']?.toString() ?? namaBaru;
  }

  // Data pelanggan hanya tersedia bagi admin/owner yang memiliki token valid.
  static Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final term = query.trim();
    if (term.length < 2) return [];
    final token = _token ?? await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) throw Exception('Sesi habis, silakan login.');
    try {
      final uri = Uri.parse('$baseUrl/search_users.php').replace(queryParameters: {'q': term});
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));
      final json = jsonDecode(response.body);
      if (json is! Map || response.statusCode != 200 || json['success'] != true) {
        throw Exception(json is Map ? (json['message'] ?? 'Gagal mencari pelanggan') : 'Respons API tidak valid');
      }
      final items = json['users'];
      if (items is! List) throw Exception('Format data pelanggan tidak valid.');
      return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } on FormatException {
      throw Exception('Respons pencarian bukan JSON. Cek PHP API.');
    } on http.ClientException {
      throw Exception('Tidak bisa terhubung ke server.');
    }
  }


  static Future<Map<String, dynamic>> _get(String path, {Map<String, String>? query}) async {
    final token = _token ?? await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) throw Exception('Sesi habis. Silakan login kembali.');
    try {
      final uri = Uri.parse('$baseUrl/$path').replace(queryParameters: query);
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 20));
      return _decodeResponse(response);
    } on FormatException {
      throw Exception('Respons server bukan JSON. Periksa PHP API.');
    } on http.ClientException {
      throw Exception('Tidak bisa tersambung ke server. Periksa Apache/XAMPP.');
    }
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('Format respons server tidak valid.');
    if (response.statusCode == 401) throw ApiUnauthorizedException();
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] != true) {
      throw Exception(decoded['message']?.toString() ?? 'Permintaan gagal (${response.statusCode}).');
    }
    return decoded;
  }

  // Data layanan selalu berasal dari MySQL. Harga dari Flutter hanya untuk estimasi tampilan;
  // create_order.php menghitung ulang harga dari database.
  static Future<List<Map<String, dynamic>>> getServices() async {
    final data = await _get('services.php');
    final list = data['services'];
    if (list is! List) throw Exception('Format daftar layanan tidak valid.');
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> updateService({required int id, required int price, required bool active}) async {
    await _request('services.php', {
      'id': id,
      'unit_price': price,
      'is_active': active ? 1 : 0,
    }, auth: true);
  }

  static Future<List<Map<String, dynamic>>> getPromos() async {
    final data = await _get('promos.php');
    final list = data['promos'];
    if (list is! List) throw Exception('Format daftar promo tidak valid.');
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> getAdminPromos() async {
    final data = await _get('promos.php');
    final list = data['promos'];
    if (list is! List) throw Exception('Format daftar promo tidak valid.');
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> createPromo({
    required String code,
    required String title,
    required String description,
    required String discountType,
    required int discountValue,
    required int minSubtotal,
    int? maxDiscount,
    int? usageLimit,
  }) async {
    await _request('promos.php', {
      'action': 'create',
      'code': code,
      'title': title,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_subtotal': minSubtotal,
      'max_discount': maxDiscount,
      'usage_limit': usageLimit,
    }, auth: true);
  }

  static Future<void> togglePromo({required int id, required bool active}) async {
    await _request('promos.php', {
      'action': 'toggle',
      'id': id,
      'is_active': active ? 1 : 0,
    }, auth: true);
  }

  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    String? promoCode,
    required String paymentMethod,
  }) async {
    final data = await _request('create_order.php', {
      'items': items,
      'promo_code': promoCode ?? '',
      'payment_method': paymentMethod,
    }, auth: true);
    final order = data['order'];
    if (order is! Map) throw Exception('Server tidak mengembalikan data pesanan.');
    return Map<String, dynamic>.from(order);
  }

  static Future<List<Map<String, dynamic>>> getMyOrders() async {
    final data = await _get('my_orders.php');
    final list = data['orders'];
    if (list is! List) throw Exception('Format riwayat pesanan tidak valid.');
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<Map<String, dynamic>> createMidtransSandboxPayment(int orderId) async {
    final data = await _request('create_payment.php', {'order_id': orderId}, auth: true);
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getPaymentStatus(int orderId) async {
    final data = await _get('payment_status.php', query: {'order_id': '$orderId'});
    final order = data['order'];
    if (order is! Map) throw Exception('Status pesanan tidak tersedia.');
    return Map<String, dynamic>.from(order);
  }

  static Future<List<Map<String, dynamic>>> getAdminOrders() async {
    final data = await _get('admin_orders.php');
    final list = data['orders'];
    if (list is! List) throw Exception('Format pesanan Admin tidak valid.');
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> updateAdminOrderStatus(int orderId, String status) async {
    await _request('admin_orders.php', {
      'action': 'update_status',
      'order_id': orderId,
      'order_status': status,
    }, auth: true);
  }

  static Future<void> markCodPaid(int orderId) async {
    await _request('admin_orders.php', {
      'action': 'mark_cod_paid',
      'order_id': orderId,
    }, auth: true);
  }

  static Future<Map<String, dynamic>> getAdminNotifications() async {
    return _get('notifications.php');
  }

  static Future<void> markNotificationRead(int id) async {
    await _request('notifications.php', {'id': id}, auth: true);
  }

  static Future<void> markAllNotificationsRead() async {
    await _request('notifications.php', {'action': 'mark_all'}, auth: true);
  }

  static Future<void> logout() async {
    try {
      await _request('logout.php', {}, auth: true);
    } catch (_) {
      // Tetap hapus sesi lokal bila server tidak bisa dihubungi.
    } finally {
      _token = null;
      nama = null;
      email = null;
      role = null;
      alamat = null;
      fotoUrl = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberKey, false);
      await _storage.delete(key: 'auth_token');
    }
  }
}

class ApiUnauthorizedException implements Exception {
  @override
  String toString() => 'Sesi kedaluwarsa. Silakan login ulang.';
}
