import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Emulator Android: 10.0.2.2. HP fisik: ganti IP LAN komputer.
  // Saat rilis: gunakan URL HTTPS server, jangan localhost.
  static const String baseUrl ='http://localhost/ayo_laundry_api';
  static const _storage = FlutterSecureStorage();
  static String? nama;
  static String? email;
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

  static Future<void> login(String emailInput, String password) async {
    final data = await _request('login.php', {'email': emailInput, 'password': password});
    final token = data['token'];
    final user = data['user'];
    if (token is! String || user is! Map) throw Exception('Data login server tidak lengkap.');
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
    nama = user['nama']?.toString();
    email = user['email']?.toString();
  }

  static Future<bool> restoreSession() async {
    _token = await _storage.read(key: 'auth_token');
    if (_token == null) return false;
    try {
      await refreshProfile();
      return true;
    } catch (_) {
      await _storage.delete(key: 'auth_token');
      _token = null;
      nama = null;
      email = null;
      return false;
    }
  }

  static Future<void> refreshProfile() async {
    final data = await _request('profile.php', {}, auth: true);
    final user = data['user'];
    if (user is! Map) throw Exception('Data profil tidak tersedia.');
    nama = user['nama']?.toString();
    email = user['email']?.toString();
  }

  static Future<void> ubahNama(String namaBaru) async {
    final data = await _request('edit_nama.php', {'nama': namaBaru}, auth: true);
    nama = data['nama']?.toString() ?? namaBaru;
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
      await _storage.delete(key: 'auth_token');
    }
  }
}
