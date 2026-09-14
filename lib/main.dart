import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Tambahan wajib 1
import 'firebase_options.dart'; // Tambahan wajib 2
import 'package:firebase_auth/firebase_auth.dart'; // Tambahan untuk sistem Login
import 'dart:io'; // Wajib ditambahin buat ngurus file gambar dari galeri
import 'package:image_picker/image_picker.dart'; // Wajib ditambahin buat buka galeri

// --- VARIABEL GLOBAL ALAMAT & HISTORY ---
String globalAlamat = 'Alamat belum diatur. Ketuk ikon pensil untuk mengisi alamat pengiriman Anda.';
int globalCountKilat = 0;
int globalCountRegular = 0;
int globalCountSetrika = 0;

// Fungsi main sekarang ditambahkan 'async'
void main() async {
  // Baris ini wajib ada agar Flutter memastikan semua komponen siap sebelum menyalakan Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Perintah untuk menyalakan Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: const LoginPage(),
    );
  }
}

// ==========================================
// HALAMAN 1: HOME PAGE
// ==========================================
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
                          _buildBanner(),
                          const SizedBox(height: 30),
                          const Text(
                            'Layanan Kami',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildServicesSection(),
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
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
        image: const DecorationImage(
          image: AssetImage('assets/ayo_laundry_promo.png'), 
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildServiceCard('Cuci Kilat', 'Rp: 10.000/Kg', Icons.local_laundry_service),
        _buildServiceCard('Cuci Reguler', 'Rp: 7.000/Kg', Icons.local_laundry_service_outlined),
        _buildServiceCard('Setrika', 'Rp: 10.000/Kg', Icons.iron),
      ],
    );
  }

  Widget _buildServiceCard(String title, String price, IconData icon) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ]
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.black87),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
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
          
          // Tombol Pindah ke Profile
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
// HALAMAN 2: PROFILE PAGE (DINAMIS & EDIT NAMA)
// ==========================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // 1. Fungsi Buka Galeri
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Kompres ukuran gambar biar gak berat
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka galeri: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 2. Fungsi Edit Nama (Simpan ke Firebase Auth)
  void _editNamaDialog(User? user) {
    TextEditingController namaController = TextEditingController(
      text: user?.displayName ?? 'Pelanggan Setia',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Nama Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: TextField(
            controller: namaController,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (namaController.text.isNotEmpty && user != null) {
                  // Update nama ke Firebase Auth
                  await user.updateDisplayName(namaController.text);
                  await user.reload(); // Refresh data user
                  setState(() {}); // Refresh tampilan UI
                }
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // 3. Fungsi Logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // 4. Fungsi Edit Alamat
  void _editAlamatDialog() {
    TextEditingController alamatController = TextEditingController(
      text: globalAlamat == 'Alamat belum diatur. Ketuk ikon pensil untuk mengisi alamat pengiriman Anda.' ? '' : globalAlamat,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Atur Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: TextField(
            controller: alamatController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ketik alamat lengkap Anda di sini...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (alamatController.text.isNotEmpty) {
                    globalAlamat = alamatController.text;
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final emailUser = user?.email ?? 'Belum Login';
    // Ambil nama dari Firebase, kalau belum di-set pakai default 'Pelanggan Setia'
    final namaUser = (user?.displayName != null && user!.displayName!.isNotEmpty) 
        ? user.displayName! 
        : 'Pelanggan Setia';

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
                        _buildProfileCard(user, namaUser, emailUser),
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

  Widget _buildProfileCard(User? user, String namaUser, String emailUser) {
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
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black87, width: 1.5),
                        image: DecorationImage(
                          image: _imageFile != null 
                              ? FileImage(_imageFile!) as ImageProvider 
                              : const AssetImage('assets/profile_pic.png'), 
                          fit: BoxFit.cover
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
                          onTap: () => _editNamaDialog(user),
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
// HALAMAN 4: PROMO PAGE
// ==========================================
class PromoPage extends StatelessWidget {
  const PromoPage({super.key});

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
                
                // Konten Utama Promo (Bisa di-scroll)
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildPromoBanner(),
                          const SizedBox(height: 15),
                          _buildCouponsContainer(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Bottom Navigation Bar Promo
                _buildPromoBottomNavigationBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Header Sama Seperti Halaman Lain ---
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

  // --- Banner Promo (Ada border putihnya sesuai mockup) ---
  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6), // Jarak untuk bikin efek border putih
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), // Melengkungkan ujung gambar
        child: Image.asset(
          'assets/ayo_laundry_promo.png', 
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // --- Wadah Putih untuk List Kupon ---
  Widget _buildCouponsContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9), // Putih sedikit keabu-abuan
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
          _buildCouponItem(
            title: 'Kupon diskon 15% persen!',
            expiry: 'Berlaku Sampai: 1 Juni 2026',
          ),
          const SizedBox(height: 30), // Jarak antar kupon
          _buildCouponItem(
            title: 'Kupon diskon 10% persen!',
            expiry: 'Berlaku Sampai: 25 Mei 2026',
          ),
        ],
      ),
    );
  }

  // --- Desain Tiap Item Kupon ---
  Widget _buildCouponItem({required String title, required String expiry}) {
    return Row(
      children: [
        // Icon Kupon Warna Orange
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.discount_outlined, color: Colors.orange, size: 24),
        ),
        const SizedBox(width: 12),
        
        // Teks Judul & Tanggal
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
                ),
              ),
              const SizedBox(height: 4),
              Text(
                expiry,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Tombol "Gunakan" Warna Hijau Terang
        ElevatedButton(
          onPressed: () {
            // Aksi kalau kupon dipencet (sementara kosong dulu)
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF76FF03), // Hijau stabilo sesuai mockup
            foregroundColor: Colors.black87, // Warna teks hitam
            elevation: 0,
            minimumSize: const Size(70, 30),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'Gunakan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        )
      ],
    );
  }

  // --- Bottom Navigation Khusus Halaman Promo ---
  Widget _buildPromoBottomNavigationBar(BuildContext context) {
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
          
          // Icon Promo Aktif (nggak butuh onTap karena lagi di sini)
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
// HALAMAN 5: PESANAN PAGE (STATEFUL)
// ==========================================
class PesananPage extends StatefulWidget {
  const PesananPage({super.key});

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  // Variabel untuk menyimpan jumlah Kilo masing-masing layanan
  int qtyCuciKilat = 0; //
  int qtyCuciNormal = 0; // 
  int qtySetrika = 0;    // 

  // Harga masing-masing layanan
  final int hargaCuciKilat = 10000;
  final int hargaCuciNormal = 7000;
  final int hargaSetrika = 10000;

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
                
                // Kontainer Putih Pesanan Utama
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 20, bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
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
                          // Daftar Pesanan (Bisa di-scroll kalau kepanjangan)
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildOrderItem(
                                    title: 'Cuci Kilat',
                                    price: hargaCuciKilat,
                                    qty: qtyCuciKilat,
                                    icon: Icons.local_laundry_service,
                                    onAdd: () => setState(() => qtyCuciKilat++),
                                    onRemove: () {
                                      if (qtyCuciKilat > 0) setState(() => qtyCuciKilat--);
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  _buildOrderItem(
                                    title: 'Cuci Normal',
                                    price: hargaCuciNormal,
                                    qty: qtyCuciNormal,
                                    icon: Icons.local_laundry_service_outlined,
                                    onAdd: () => setState(() => qtyCuciNormal++),
                                    onRemove: () {
                                      if (qtyCuciNormal > 0) setState(() => qtyCuciNormal--);
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  _buildOrderItem(
                                    title: 'Setrika',
                                    price: hargaSetrika,
                                    qty: qtySetrika,
                                    icon: Icons.iron,
                                    onAdd: () => setState(() => qtySetrika++),
                                    onRemove: () {
                                      if (qtySetrika > 0) setState(() => qtySetrika--);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Tombol Bawah (Batal & Lanjut)
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Aksi reset atau batal
                                    setState(() {
                                      qtyCuciKilat = 0;
                                      qtyCuciNormal = 0;
                                      qtySetrika = 0;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE0E0E0), // Abu-abu
                                    foregroundColor: Colors.black87,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Batalkan pembayaran',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Pindah ke halaman Pembayaran
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const PembayaranPage()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    // ... kode style tombol lu tetap biarkan sama
                                    backgroundColor: const Color(0xFF76FF03), // Hijau stabilo
                                    foregroundColor: Colors.black87,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Lanjut Pembayaran',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Bottom Navigation Bar Pesanan
                _buildPesananBottomNavigationBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Header ---
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

  // --- Widget Kustom untuk Baris Item Pesanan dengan Plus/Minus ---
  Widget _buildOrderItem({
    required String title,
    required int price,
    required int qty,
    required IconData icon,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    // Format angka ribuan sederhana
    String formattedPrice = price.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ".");
    String formattedTotal = (price * qty).toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ".");

    return Row(
      children: [
        // Kotak Icon
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9), // Hijau sangat muda pudar
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.black87, size: 28),
        ),
        const SizedBox(width: 15),
        
        // Teks Judul & Perhitungan
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp:$formattedPrice x ${qty}Kg = $formattedTotal',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),

        // Tombol Plus Minus
        Row(
          children: [
            InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.remove, size: 16, color: Colors.red),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$qty',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            InkWell(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.green),
              ),
            ),
          ],
        )
      ],
    );
  }

  // --- Bottom Nav ---
  Widget _buildPesananBottomNavigationBar(BuildContext context) {
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
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
          
          // Icon Pesanan Aktif
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
          
          _BottomNavIcon(
            icon: Icons.local_offer_outlined, 
            label: 'Promo',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PromoPage())),
          ),
          _BottomNavIcon(
            icon: Icons.mail_outline, 
            label: 'Inbox',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const InboxPage())),
          ),
          // KODE BARU PAKAI FOTO PROFIL
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
// HALAMAN 6: PEMBAYARAN PAGE (STATEFUL)
// ==========================================
class PembayaranPage extends StatefulWidget {
  const PembayaranPage({super.key});

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  // Variabel untuk menyimpan metode pembayaran yang dipilih
  String _selectedPayment = 'COD'; // Default terpilih

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
                
                // Kontainer Putih Pilihan Pembayaran
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 20, bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih Metode Pembayaran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // List Pembayaran yang bisa di-scroll
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildPaymentOption('Cash on Delivery (COD)', 'COD', Icons.money),
                                  _buildPaymentOption('DANA', 'DANA', Icons.account_balance_wallet),
                                  _buildPaymentOption('ShopeePay', 'ShopeePay', Icons.shopping_bag),
                                  _buildPaymentOption('GoPay', 'GoPay', Icons.motorcycle),
                                  _buildPaymentOption('OVO', 'OVO', Icons.circle),
                                ],
                              ),
                            ),
                          ),
                          
                          // Tombol Lanjutkan Pembayaran
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Panggil fungsi Pop-up Dialog
                                _tampilkanDialogSukses(context, _selectedPayment);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF76FF03), // Hijau stabilo
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Lanjutkan Pembayaran',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Bottom Navigation Bar
                _buildPembayaranBottomNavigationBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Header ---
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

  // --- Widget Kustom untuk Baris Opsi Pembayaran ---
  Widget _buildPaymentOption(String title, String value, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPayment = value;
        });
      },
      behavior: HitTestBehavior.opaque, // Area klik jadi lebih luas
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _selectedPayment == value ? Colors.blue : Colors.grey.shade300,
            width: _selectedPayment == value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueGrey, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPayment,
              activeColor: Colors.blue,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPayment = newValue!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Nav ---
  Widget _buildPembayaranBottomNavigationBar(BuildContext context) {
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
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (Route<dynamic> route) => false,
            ),
          ),
          const _BottomNavIcon(icon: Icons.receipt_long_outlined, label: 'Pesanan'),
          _BottomNavIcon(
            icon: Icons.local_offer_outlined, 
            label: 'Promo',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PromoPage())),
          ),
          _BottomNavIcon(
            icon: Icons.mail_outline, 
            label: 'Inbox',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const InboxPage())),
          ),
          _BottomNavProfileIcon(
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI POP-UP SUKSES DENGAN ALAMAT PENGIRIMAN ---
  void _tampilkanDialogSukses(BuildContext context, String metodeBayar) {
    setState(() {
      globalCountKilat += 1; // Otomatis nambah 1 ke history
    });
    showDialog(
      context: context,
      barrierDismissible: false, // Biar user gak bisa asal tutup pop-up tanpa pencet tombol OK
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 15),
              Text(
                'Pesanan Berhasil!', 
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Metode: $metodeBayar', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 20),
              const Text('Dikirim ke:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(
                globalAlamat, // Ganti teks mati menjadi variabel ini
                style: const TextStyle(color: Colors.black87, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kurir AYO LAUNDRY akan segera menjemput pakaian anda.', 
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Tutup dialog dan lempar user kembali ke halaman utama dari awal
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F), // Kuning
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Kembali ke Beranda', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// HALAMAN 7: LOGIN PAGE (DINAMIS FIREBASE)
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi Login ke Firebase
  Future<void> _loginDinamic() async {
    setState(() {
      _isLoading = true; // Nyalakan loading
    });

    try {
      // Proses ngecek ke server Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Kalau sukses, masuk ke HomePage
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Kalau gagal (password salah / email gak ada), tangkap errornya
      String pesanError = 'Terjadi kesalahan.';
      if (e.code == 'user-not-found') {
        pesanError = 'Email tidak terdaftar.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        pesanError = 'Password salah.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email salah.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanError), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Matikan loading
        });
      }
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
// HALAMAN 8: REGISTER PAGE (DINAMIS FIREBASE)
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

  // Fungsi Register ke Firebase
  Future<void> _registerDinamic() async {
    // Validasi kalau ada kolom yang kosong
    if (_namaController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom harus diisi!'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Bikin akun di server Firebase
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // (Opsional) Lu bisa nyimpen Nama user nanti pakai Firestore/Database.
      // Untuk sekarang, kita buatkan akunnya dulu.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dibuat! Silakan Login.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Kembali ke halaman Login
      }
    } on FirebaseAuthException catch (e) {
      String pesanError = 'Terjadi kesalahan.';
      if (e.code == 'weak-password') {
        pesanError = 'Password terlalu lemah (minimal 6 karakter).';
      } else if (e.code == 'email-already-in-use') {
        pesanError = 'Email sudah terdaftar. Silakan login.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email salah.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesanError), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                          labelText: 'Password (min. 6 karakter)',
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
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 1.5),
              image: const DecorationImage(
                image: AssetImage('assets/photo_profile.png'), // Pastikan nama file ini sama
                fit: BoxFit.cover,
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