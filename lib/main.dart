import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'admin_owner_pages.dart';
import 'package:image_picker/image_picker.dart'; // Wajib ditambahin buat buka galeri
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' as foundation;

// --- VARIABEL GLOBAL ALAMAT & HISTORY ---
String globalAlamat = 'Alamat belum diatur. Ketuk ikon pensil untuk mengisi alamat pengiriman Anda.';
int globalCountKilat = 0;
int globalCountRegular = 0;
int globalCountSetrika = 0;
String? selectedPromoCode;

// Foto profil bersama untuk halaman Profil dan bottom navigation.
// Gambar diambil dari URL server setelah profil dimuat; MemoryImage dipakai
// sementara sesudah pengguna memilih foto baru.
final foundation.ValueNotifier<ImageProvider?> fotoProfilNotifier =
    foundation.ValueNotifier<ImageProvider?>(null);

const String _alamatDefault =
    'Alamat belum diatur. Ketuk ikon pensil untuk mengisi alamat pengiriman Anda.';

void sinkronProfilLokal() {
  globalAlamat = (ApiService.alamat?.isNotEmpty ?? false)
      ? ApiService.alamat!
      : _alamatDefault;

  final fotoUrl = ApiService.fotoUrl;
  fotoProfilNotifier.value =
      (fotoUrl == null || fotoUrl.isEmpty) ? null : NetworkImage(fotoUrl);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AyoLaundryApp());
}

class AyoLaundryApp extends StatelessWidget {
  const AyoLaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayo Laundry UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      // Aplikasi dimulai dari HomePage
      home: const AuthGate(),
    );
  }
}

// ==========================================
// HALAMAN 1: HOME PAGE
// ==========================================
// Halaman awal berdasarkan role yang sudah diterima dari PHP API.
Widget halamanSesuaiRole() {
  switch (ApiService.role) {
    case 'admin':
      return const AdminPage();
    case 'owner':
      return const OwnerPage();
    case 'pelanggan':
      return const HomePage();
    default:
      return const LoginPage();
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _session = _checkSession();

  Future<bool> _checkSession() async {
    final valid = await ApiService.restoreSession();
    if (valid) sinkronProfilLokal();
    return valid;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _session,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return snapshot.data == true ? halamanSesuaiRole() : const LoginPage();
    },
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Latar Belakang Diagonal
          Positioned.fill(
            child: CustomPaint(
              painter: DiagonalBackgroundPainter(),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildBanner(), // Banner Promo Atas
                          const SizedBox(height: 30),
                          
                          // BANNER LAYANAN KAMI YANG BARU (GAMBAR)
                          _buildBannerLayanan(), 
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Panggil Bottom Nav dengan mengirimkan context
                _buildBottomNavigationBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              'assets/ayo_laundry.png',
              height: 45,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/ayo_laundry_promo.png',
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE4F6FF), Color(0xFFFFF1B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('SPECIAL OFFER!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006BCB))),
                SizedBox(height: 4),
                Text('DISKON 25%', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Color(0xFF0077D9))),
                Text('UNTUK SEMUA LAYANAN AYO LAUNDRY', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF263E50))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- FUNGSI BARU: MENAMPILKAN GAMBAR LAYANAN KAMI ---
  Widget _buildBannerLayanan() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16), // Sudut melengkung biar rapi
      child: Image.asset(
        'assets/membership.png', // Pastikan nama file gambarnya sudah benar
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          color: const Color(0xFF17163E),
          child: const Text(
            'YUK JADI MEMBER CUCI DI SINI!\nBAYAR DI AKHIR BULAN',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ),
    );
  }

  // Perhatikan: Menambahkan parameter BuildContext context
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFD54F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _BottomNavIcon(icon: Icons.home_outlined, label: 'Beranda'),
          // Tombol Pindah ke Pesanan
          _BottomNavIcon(
            icon: Icons.receipt_long_outlined, 
            label: 'Pesanan',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PesananPage()),
              );
            },
          ),
          // Tombol Pindah ke Promo
          _BottomNavIcon(
            icon: Icons.local_offer_outlined, 
            label: 'Promo',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PromoPage()),
              );
            },
          ),
          // Tombol Pindah ke Inbox
          _BottomNavIcon(
            icon: Icons.mail_outline, 
            label: 'Inbox',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const InboxPage()),
              );
            },
          ),
          
          // Tombol Pindah ke Profile
          _BottomNavProfileIcon(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HALAMAN 2: PROFILE PAGE (DINAMIS & EDIT NAMA)
// ==========================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();

  // 1. Fungsi Buka Galeri
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Kompres ukuran gambar biar gak berat
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (!mounted) return;
        await ApiService.uploadFotoProfil(bytes);
        if (!mounted) return;
        fotoProfilNotifier.value = MemoryImage(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil disimpan di server')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka galeri: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Edit nama melalui PHP API, lalu update tampilan profil.
  Future<void> _editNamaDialog() async {
    final namaController = TextEditingController(text: ApiService.nama ?? '');
    final namaBaru = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Nama Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: namaController,
          decoration: InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, namaController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    namaController.dispose();
    if (!mounted || namaBaru == null || namaBaru.isEmpty) return;
    try {
      await ApiService.ubahNama(namaBaru);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama berhasil diperbarui')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    // Hanya bersihkan cache tampilan. File foto di server dan path MySQL tidak dihapus.
    fotoProfilNotifier.value = null;
    globalAlamat = _alamatDefault;
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // Alamat pengiriman disimpan permanen melalui PHP API ke MySQL.
  Future<void> _editAlamatDialog() async {
    final controller = TextEditingController(text: ApiService.alamat ?? '');
    final alamatBaru = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atur Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Ketik alamat lengkap Anda di sini...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || alamatBaru == null) return;

    try {
      await ApiService.simpanAlamat(alamatBaru);
      if (!mounted) return;
      setState(sinkronProfilLokal);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat berhasil disimpan ke MySQL')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailUser = ApiService.email ?? 'Belum Login';
    final namaUser = ApiService.nama ?? 'Pelanggan Setia';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: DiagonalBackgroundPainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        _buildProfileCard(namaUser, emailUser),
                      ],
                    ),
                  ),
                ),
                _buildProfileBottomNavigationBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset('assets/ayo_laundry.png', height: 45, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String namaUser, String emailUser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // FOTO PROFIL BISA DIKLIK
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ValueListenableBuilder<ImageProvider?>(
                      valueListenable: fotoProfilNotifier,
                      builder: (context, photo, _) => Container(
                        width: 70,
                        height: 70,
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black87, width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image(
                            image: photo ?? const AssetImage('assets/profile_pic.png'),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const ColoredBox(
                              color: Color(0xFFE8EEF4),
                              child: Icon(Icons.person, color: Colors.blueGrey, size: 38),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAMA BISA DI-EDIT BERSAMA IKON PENSIL
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            namaUser, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _editNamaDialog,
                          child: const Icon(Icons.edit, color: Colors.blue, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(emailUser, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 25),
          const Text('History Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 15),
          
          // HISTORY PEMBELIAN DINAMIS (Mengambil dari Variabel Global)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHistoryItem('Cuci Kilat', '$globalCountKilat'),
              _buildHistoryItem('Cuci Regular', '$globalCountRegular'),
              _buildHistoryItem('Setrika', '$globalCountSetrika'),
            ],
          ),
          
          const SizedBox(height: 25),
          const Divider(color: Colors.grey, thickness: 0.5),
          const SizedBox(height: 15),
          const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 10),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  globalAlamat,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                ),
              ),
              GestureDetector(
                onTap: _editAlamatDialog,
                child: const Icon(Icons.edit_location_alt_outlined, color: Colors.blue, size: 26),
              ),
            ],
          ),
          
          const SizedBox(height: 25),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Keluar (Logout)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String count) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
          child: Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue)),
        ),
      ],
    );
  }

  Widget _buildProfileBottomNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFD54F),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavIcon(
            icon: Icons.home_outlined, label: 'Beranda',
            onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false),
          ),
          _BottomNavIcon(
            icon: Icons.receipt_long_outlined, label: 'Pesanan',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PesananPage())),
          ),
          _BottomNavIcon(
            icon: Icons.local_offer_outlined, label: 'Promo',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PromoPage())),
          ),
          _BottomNavIcon(
            icon: Icons.mail_outline, label: 'Inbox',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const InboxPage())),
          ),
          const _BottomNavProfileIcon(),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET HELPER & CUSTOM PAINTER
// ==========================================
// ==========================================
// HALAMAN 3: INBOX PAGE
// ==========================================
class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Latar Belakang Diagonal
          Positioned.fill(
            child: CustomPaint(
              painter: DiagonalBackgroundPainter(),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                
                // Kontainer Putih Inbox
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Expanded(
                          child: _buildInboxContainer(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Navigation Bar Inbox
                _buildInboxBottomNavigationBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              'assets/ayo_laundry.png',
              height: 45,
              fit: BoxFit.cover,
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildInboxContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Warna putih keabu-abuan sesuai mockup
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          _buildInboxItem(
            title: 'Pesanan anda akan sampai\ndalam beberapa menit',
            time: 'Send: 5 Minutes ago',
            hasNotification: true, // Ubah ke false kalau mau ngilangin titik merahnya
          ),
          // Kalau nanti ada pesan lain, tinggal panggil _buildInboxItem() lagi di sini
        ],
      ),
    );
  }

  // Komponen khusus untuk isi pesan
  Widget _buildInboxItem({required String title, required String time, bool hasNotification = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Amplop dengan Notifikasi Titik Merah
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.mail_outline, size: 30, color: Colors.black87),
            if (hasNotification)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 15),
        
        // Teks Pesan
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInboxBottomNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFD54F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavIcon(
            icon: Icons.home_outlined, 
            label: 'Beranda',
            onTap: () {
              // Navigasi kembali ke Home dengan menghapus semua halaman di atasnya
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          // Tombol Pindah ke Pesanan
          _BottomNavIcon(
            icon: Icons.receipt_long_outlined, 
            label: 'Pesanan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PesananPage()),
              );
            },
          ),
          // Tombol Pindah ke Promo
          _BottomNavIcon(
            icon: Icons.local_offer_outlined, 
            label: 'Promo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PromoPage()),
              );
            },
          ),
          
          // Icon Inbox aktif (tidak dipasang navigasi karena sedang di halaman Inbox)
          // Tombol Pindah ke Inbox
          _BottomNavIcon(
            icon: Icons.mail_outline, 
            label: 'Inbox',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InboxPage()),
              );
            },
          ),
          
          // Tombol Pindah ke Profile (Ganti pakai ini)
          _BottomNavProfileIcon(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HALAMAN 4: PROMO PAGE (DINAMIS DARI MYSQL)
// ==========================================
class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _promos = [];

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getPromos();
      if (!mounted) return;
      setState(() { _promos = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  String _rupiah(dynamic value) {
    final n = int.tryParse(value.toString()) ?? 0;
    return 'Rp${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }

  String _expiry(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Tanpa batas tanggal';
    final date = DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));
    if (date == null) return 'Berlaku sesuai ketentuan';
    return 'Berlaku sampai ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _usePromo(Map<String, dynamic> promo) {
    selectedPromoCode = promo['code']?.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kode ${selectedPromoCode ?? ''} dipilih. Lanjutkan ke Pesanan.')),
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PesananPage()));
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(8),
        child: Image.asset('assets/ayo_laundry.png', height: 45, fit: BoxFit.cover)),
    ]),
  );

  Widget _buildPromoBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
    child: ClipRRect(borderRadius: BorderRadius.circular(12),
      child: Image.asset('assets/ayo_laundry_promo.png', height: 160, width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(height: 160, color: const Color(0xFFE8F5FF),
          alignment: Alignment.center, child: const Text('PROMO AYO LAUNDRY',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue))))),
  );

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final code = promo['code']?.toString() ?? '';
    final isPercent = promo['discount_type'] == 'percent';
    final value = int.tryParse('${promo['discount_value']}') ?? 0;
    final discount = isPercent ? 'Diskon $value%' : 'Diskon ${_rupiah(value)}';
    final minimum = int.tryParse('${promo['min_subtotal']}') ?? 0;
    final active = (promo['is_active']?.toString() ?? '1') == '1';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 1.5), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.discount_outlined, color: Colors.orange, size: 26)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(promo['title']?.toString() ?? discount,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 3),
          Text('$discount • Kode: $code', style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(promo['description']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text('Min. transaksi ${_rupiah(minimum)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(_expiry(promo['ends_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: active ? () => _usePromo(promo) : null,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF76FF03), foregroundColor: Colors.black87,
            elevation: 0, minimumSize: const Size(70, 34), padding: const EdgeInsets.symmetric(horizontal: 10)),
          child: const Text('Gunakan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(color: Color(0xFFFFD54F), borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _BottomNavIcon(icon: Icons.home_outlined, label: 'Beranda', onTap: () => Navigator.popUntil(context, (route) => route.isFirst)),
      _BottomNavIcon(icon: Icons.receipt_long_outlined, label: 'Pesanan', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PesananPage()))),
      const _BottomNavIcon(icon: Icons.local_offer_outlined, label: 'Promo'),
      _BottomNavIcon(icon: Icons.mail_outline, label: 'Inbox', onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InboxPage()))),
      _BottomNavProfileIcon(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: DiagonalBackgroundPainter())),
      SafeArea(child: Column(children: [
        _buildHeader(),
        Expanded(child: RefreshIndicator(
          onRefresh: _loadPromos,
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            const SizedBox(height: 10),
            _buildPromoBanner(),
            const SizedBox(height: 18),
            Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Promo & Kupon Aktif', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                if (_error != null) Column(children: [Text(_error!, style: const TextStyle(color: Colors.red)),
                  TextButton.icon(onPressed: _loadPromos, icon: const Icon(Icons.refresh), label: const Text('Coba lagi'))]),
                if (!_loading && _error == null && _promos.isEmpty) const Text('Belum ada promo aktif.'),
                if (!_loading && _error == null) ..._promos.map(_buildPromoCard),
              ])),
            const SizedBox(height: 20),
          ]),
        )),
        _buildBottomNavigationBar(context),
      ])),
    ]),
  );
}

// ==========================================
// HALAMAN 5: PESANAN PAGE (LAYANAN DARI MYSQL)
// ==========================================
class PesananPage extends StatefulWidget {
  const PesananPage({super.key});
  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  final Map<int, int> _cart = {};
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getServices();
      if (!mounted) return;
      setState(() { _services = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  int _integer(dynamic value) => int.tryParse(value.toString()) ?? 0;
  String _rupiah(int value) => 'Rp${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  void _changeQuantity(Map<String, dynamic> service, int change) {
    final id = _integer(service['id']);
    final minimum = _integer(service['min_qty']).clamp(1, 500).toInt();
    final current = _cart[id] ?? 0;
    int next;
    if (change > 0) {
      next = current == 0 ? minimum : current + 1;
    } else {
      next = current <= minimum ? 0 : current - 1;
    }
    setState(() {
      if (next <= 0) { _cart.remove(id); } else { _cart[id] = next; }
    });
  }

  List<Map<String, dynamic>> get _checkoutItems => _cart.entries
      .map((entry) => {'service_id': entry.key, 'quantity': entry.value})
      .toList();

  int get _totalItems => _cart.values.fold(0, (sum, quantity) => sum + quantity);

  int get _estimatedTotal => _cart.entries.fold(0, (sum, entry) {
    final service = _services.firstWhere((s) => _integer(s['id']) == entry.key, orElse: () => {});
    return sum + (_integer(service['unit_price']) * entry.value);
  });

  Widget _buildCategoryCard(String category, List<Map<String, dynamic>> services) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        key: PageStorageKey<String>('kategori_$category'),
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: EdgeInsets.zero,
        backgroundColor: const Color(0xFF2C3E50),
        collapsedBackgroundColor: const Color(0xFF2C3E50),
        collapsedTextColor: Colors.white,
        textColor: Colors.white,
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: [Container(color: const Color(0xFFF8F5FA), child: Column(children: [
          for (int index = 0; index < services.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            Builder(builder: (context) {
              final service = services[index];
              final id = _integer(service['id']);
              final qty = _cart[id] ?? 0;
              final unit = service['unit_label']?.toString() ?? 'pcs';
              final min = _integer(service['min_qty']);
              return Padding(padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(service['name']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                    Text('${_rupiah(_integer(service['unit_price']))} / $unit${min > 1 ? ' • Min $min $unit' : ''}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ])),
                  IconButton(onPressed: () => _changeQuantity(service, -1), icon: const Icon(Icons.remove, color: Colors.red),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFD8DC), minimumSize: const Size(32,32), padding: const EdgeInsets.all(4)),
                    constraints: const BoxConstraints(minWidth: 32,minHeight: 32)),
                  SizedBox(width: 36, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  IconButton(onPressed: () => _changeQuantity(service, 1), icon: const Icon(Icons.add, color: Colors.green),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFCBF1D6), minimumSize: const Size(32,32), padding: const EdgeInsets.all(4)),
                    constraints: const BoxConstraints(minWidth: 32,minHeight: 32)),
                ]));
            }),
          ],
        ]))],
      ),
    );
  }

  Widget _buildCheckoutBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0,-5))]),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (selectedPromoCode != null) Row(children: [
        const Icon(Icons.discount_outlined, color: Colors.green, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Text('Promo dipilih: $selectedPromoCode', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600))),
        TextButton(onPressed: () => setState(() => selectedPromoCode = null), child: const Text('Hapus')),
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total Item', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text('$_totalItems', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19))]),
          const SizedBox(width: 24),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Estimasi Harga', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text(_rupiah(_estimatedTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
        ]),
        ElevatedButton(onPressed: _cart.isEmpty ? null : () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PembayaranPage(items: _checkoutItems, promoCode: selectedPromoCode)));
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD54F), foregroundColor: Colors.black87),
          child: const Text('Lanjut Bayar')),
      ]),
      const SizedBox(height: 3),
      const Text('Harga akhir dan promo akan dihitung ulang oleh server.', style: TextStyle(fontSize: 10, color: Colors.grey)),
    ]),
  );

  Widget _buildBottomNavigationBar(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(color: Color(0xFFFFD54F), borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _BottomNavIcon(icon: Icons.home_outlined,label:'Beranda',onTap:()=>Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const HomePage()),(r)=>false)),
      const _BottomNavIcon(icon: Icons.receipt_long_outlined,label:'Pesanan'),
      _BottomNavIcon(icon: Icons.local_offer_outlined,label:'Promo',onTap:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const PromoPage()))),
      _BottomNavIcon(icon: Icons.mail_outline,label:'Inbox',onTap:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const InboxPage()))),
      _BottomNavProfileIcon(onTap:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const ProfilePage()))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final service in _services) {
      final category = service['category']?.toString() ?? 'Layanan lainnya';
      grouped.putIfAbsent(category, () => []).add(service);
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Buat Pesanan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: const Color(0xFFFFD54F), elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context))),
      body: Column(children: [
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              TextButton.icon(onPressed: _loadServices, icon: const Icon(Icons.refresh), label: const Text('Muat ulang layanan')),
            ])))
          : RefreshIndicator(onRefresh: _loadServices, child: ListView(padding: const EdgeInsets.all(16), children: [
              if (grouped.isEmpty) const Text('Belum ada layanan aktif.'),
              for (final entry in grouped.entries) ...[
                _buildCategoryCard(entry.key, entry.value),
                const SizedBox(height: 16),
              ],
            ]))),
        _buildCheckoutBar(),
      ]),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}

// ==========================================
// HALAMAN 6: PEMBAYARAN (COD + MIDTRANS SANDBOX)
// ==========================================
class PembayaranPage extends StatefulWidget {
  const PembayaranPage({super.key, required this.items, this.promoCode});
  final List<Map<String, dynamic>> items;
  final String? promoCode;
  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  String _selectedPayment = 'COD';
  bool _loading = false;
  Map<String, dynamic>? _createdOrder;
  String? _paymentUrl;
  String? _error;

  Future<void> _submitOrder() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_createdOrder == null) {
        _createdOrder = await ApiService.createOrder(
          items: widget.items,
          promoCode: widget.promoCode,
          paymentMethod: _selectedPayment,
        );
        selectedPromoCode = null;
      }
      if (_selectedPayment == 'COD') {
        if (!mounted) return;
        await _showOrderCreatedDialog();
      } else {
        await _createAndOpenPayment();
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createAndOpenPayment() async {
    final orderId = int.tryParse('${_createdOrder?['id']}');
    if (orderId == null) throw Exception('ID pesanan tidak ditemukan.');
    final payment = await ApiService.createMidtransSandboxPayment(orderId);
    final url = payment['redirect_url']?.toString();
    if (url == null || url.isEmpty) throw Exception('Link pembayaran tidak diterima dari server.');
    if (!mounted) return;
    setState(() => _paymentUrl = url);
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Browser tidak terbuka. Gunakan tombol Buka Halaman Pembayaran di layar.')));
    }
  }

  Future<void> _checkPaymentStatus() async {
    final orderId = int.tryParse('${_createdOrder?['id']}');
    if (orderId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final status = await ApiService.getPaymentStatus(orderId);
      if (!mounted) return;
      setState(() {
        _createdOrder = {...?_createdOrder, ...status};
      });
      final paymentStatus = status['payment_status']?.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        paymentStatus == 'settlement' || paymentStatus == 'capture'
          ? 'Pembayaran sudah dikonfirmasi server.'
          : 'Status pembayaran: ${paymentStatus ?? 'belum tersedia'}')));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showOrderCreatedDialog() async {
    final code = _createdOrder?['order_code']?.toString() ?? '-';
    final total = int.tryParse('${_createdOrder?['total']}') ?? 0;
    final amount = 'Rp${total.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    await showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: const Column(children: [Icon(Icons.check_circle, color: Colors.green, size: 56), SizedBox(height: 10), Text('Pesanan Tersimpan')]),
      content: Text('Nomor: $code\nTotal: $amount\nMetode: COD\n\nPesanan sudah masuk ke sistem dan menunggu konfirmasi Admin. Pembayaran dilakukan saat serah terima.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false); }, child: const Text('Kembali ke Beranda'))],
    ));
  }

  Widget _paymentOption(String title, String value, IconData icon, String subtitle) => InkWell(
    onTap: _createdOrder == null ? () => setState(() => _selectedPayment = value) : null,
    child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _selectedPayment == value ? Colors.blue : Colors.grey.shade300, width: _selectedPayment == value ? 2 : 1)),
      child: Row(children: [Icon(icon, color: Colors.blueGrey, size: 28), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))])),
        Radio<String>(value: value, groupValue: _selectedPayment, onChanged: _createdOrder == null ? (v) => setState(() => _selectedPayment = v!) : null),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final code = _createdOrder?['order_code']?.toString();
    final total = int.tryParse('${_createdOrder?['total']}') ?? 0;
    final orderStatus = _createdOrder?['order_status']?.toString() ?? 'menunggu_pembayaran';
    final paymentStatus = _createdOrder?['payment_status']?.toString() ?? 'pending';
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran'), backgroundColor: const Color(0xFFFFD54F), foregroundColor: Colors.black87),
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: DiagonalBackgroundPainter())),
        SafeArea(child: Column(children: [
          Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
            Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                _paymentOption('Cash on Delivery (COD)', 'COD', Icons.money, 'Bayar saat serah terima dengan Admin/Kurir.'),
                _paymentOption('Pembayaran Online (Midtrans Sandbox)', 'MIDTRANS', Icons.payment, 'Simulasi pembayaran. Tidak memotong uang sungguhan.'),
              ])),
            if (_createdOrder != null) ...[
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Pesanan sudah dibuat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8), Text('Nomor: $code'), Text('Total: ${_formatRupiah(total)}'),
                  Text('Status pesanan: ${orderStatus.replaceAll('_',' ')}'),
                  Text('Status pembayaran: $paymentStatus'),
                  if (_paymentUrl != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse(_paymentUrl!), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.open_in_new), label: const Text('Buka Halaman Pembayaran'))),
                  ],
                  const SizedBox(height: 6),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _loading ? null : _checkPaymentStatus,
                    icon: const Icon(Icons.refresh), label: const Text('Periksa Status Pembayaran'))),
                  if (paymentStatus == 'pending' && _selectedPayment == 'MIDTRANS' && _paymentUrl == null)
                    SizedBox(width: double.infinity, child: TextButton(onPressed: _loading ? null : _createAndOpenPayment, child: const Text('Coba buat link pembayaran lagi'))),
                ])),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: const TextStyle(color: Colors.red))),
            ],
            const SizedBox(height: 16),
            const Text('Catatan: status pembayaran online hanya berubah setelah PHP menerima dan memverifikasi notifikasi resmi dari Midtrans.',
              style: TextStyle(color: Colors.white, fontSize: 12)),
          ])),
          SizedBox(width: double.infinity, child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: ElevatedButton(onPressed: _loading || _createdOrder != null ? null : _submitOrder,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF76FF03), foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 15)),
              child: _loading ? const SizedBox(height: 20,width: 20,child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_selectedPayment == 'COD' ? 'Buat Pesanan COD' : 'Buat Pesanan & Bayar Online')))),
        ])),
      ]),
      bottomNavigationBar: Container(color: const Color(0xFFFFD54F), padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _BottomNavIcon(icon: Icons.home_outlined,label:'Beranda',onTap:()=>Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const HomePage()),(r)=>false)),
          const _BottomNavIcon(icon: Icons.receipt_long_outlined,label:'Pesanan'),
          _BottomNavIcon(icon: Icons.local_offer_outlined,label:'Promo',onTap:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const PromoPage()))),
          _BottomNavIcon(icon: Icons.mail_outline,label:'Inbox',onTap:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const InboxPage()))),
          _BottomNavProfileIcon(onTap:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const ProfilePage()))),
        ])),
    );
  }

  String _formatRupiah(int value) => 'Rp${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
}

// HALAMAN 7: LOGIN PAGE (PHP + MYSQL)
// ==========================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _rememberMe = false;
  bool _isLoading = false; // Variabel penanda loading
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  List<String> _recentEmails = [];

  @override
  void initState() {
    super.initState();
    _loadRecentEmails();
  }

  Future<void> _loadRecentEmails() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _recentEmails = prefs.getStringList('recent_login_emails') ?? []);
  }

  Future<void> _saveRecentEmail(String address) async {
    if (!_rememberMe) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = [address, ..._recentEmails.where((e) => e != address)].take(5).toList();
    await prefs.setStringList('recent_login_emails', updated);
    if (mounted) setState(() => _recentEmails = updated);
  }

  Future<void> _clearRecentEmails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_login_emails');
    if (mounted) setState(() => _recentEmails = []);
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginDinamic() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi email dan password.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );
      sinkronProfilLokal();
      await _saveRecentEmail(_emailController.text.trim());
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => halamanSesuaiRole()), (route) => false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: DiagonalBackgroundPainter()),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/ayo_laundry.png', height: 60),
                      ),
                      const SizedBox(height: 30),
                      const Text('Selamat Datang!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      
                      TextField(
                        controller: _emailController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (_recentEmails.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ..._recentEmails.where((e) => _emailController.text.isEmpty || e.toLowerCase().contains(_emailController.text.toLowerCase())).take(4).map(
                          (e) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.history, size: 18),
                            title: Text(e, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                            onTap: () => setState(() {
                              _emailController.text = e;
                              _emailController.selection = TextSelection.collapsed(offset: e.length);
                            }),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _clearRecentEmails,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Hapus riwayat email'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 15),
                      
                      TextField(
                        controller: _passwordController,
                        obscureText: true, 
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: Colors.blue,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                          ),
                          const Text('Ingat Saya', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _loginDinamic, // Kunci tombol saat loading
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD54F),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                              : const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Belum punya akun? '),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                            child: const Text('Daftar di sini', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HALAMAN 8: REGISTER PAGE (PHP + MYSQL)
// ==========================================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerDinamic() async {
    if (_namaController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom harus diisi!'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.register(_namaController.text.trim(), _emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Akun dibuat. Silakan login!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: DiagonalBackgroundPainter()),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/ayo_laundry.png', height: 60),
                      ),
                      const SizedBox(height: 30),
                      const Text('Buat Akun Baru', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      
                      TextField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password (min. 8 karakter)',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _registerDinamic,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF76FF03), 
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                              : const Text('REGISTER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Kembali ke Login', style: TextStyle(color: Colors.grey)),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// Class yang sudah di-upgrade agar bisa menerima fungsi klik (onTap)
class _BottomNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomNavIcon({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET HELPER KHUSUS ICON PROFIL DENGAN GAMBAR ---
class _BottomNavProfileIcon extends StatelessWidget {
  final VoidCallback? onTap;

  const _BottomNavProfileIcon({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<ImageProvider?>(
            valueListenable: fotoProfilNotifier,
            builder: (context, photo, _) => Container(
              width: 28,
              height: 28,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black87, width: 1.5),
              ),
              child: ClipOval(
                child: Image(
                  image: photo ?? const AssetImage('assets/profile_pic.png'),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const ColoredBox(
                    color: Color(0xFFE8EEF4),
                    child: Icon(Icons.person, color: Colors.blueGrey, size: 18),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class DiagonalBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBlue = Paint()..color = const Color(0xFF2196F3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBlue);

    final paintYellow = Paint()..color = const Color(0xFFFFD54F);
    final path = Path();
    
    path.lineTo(size.width * 0.9, 0); 
    path.lineTo(0, size.height * 0.85); 
    path.lineTo(0, 0); 
    path.close();

    canvas.drawPath(path, paintYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}