import 'package:flutter/material.dart';
import 'dart:async';
import 'services/api_service.dart';
import 'main.dart' show LoginPage;

// AYO Laundry - Dashboard Admin dan Owner; UI demo, belum tersambung MySQL.
// Hak akses role WAJIB diperiksa di PHP API sebelum digunakan di produksi.
// Tambahkan file ini ke lib/admin_owner_pages.dart, lalu import di main.dart.
const _yellow = Color(0xFFFFD54F);
const _navy = Color(0xFF2C3E50);
const _pageBg = Color(0xFF2196F3);
const _green = Color(0xFF76FF03);

class LaundryRecord {
  LaundryRecord(this.name, this.subtitle, {this.price = 0, this.status = 'Aktif'});
  String name;
  String subtitle;
  int price;
  String status;
}

class LaundryDemoStore {
  static final services = <LaundryRecord>[
    LaundryRecord('Cuci Setrika', 'Kiloan • Min. 3 kg', price: 7000),
    LaundryRecord('Cuci Lipat', 'Kiloan • Min. 3 kg', price: 5000),
    LaundryRecord('Setrika', 'Kiloan • Min. 3 kg', price: 5000),
    LaundryRecord('Kaos', 'Satuan', price: 15000),
    LaundryRecord('Kemeja', 'Satuan', price: 15000),
    LaundryRecord('Celana', 'Satuan', price: 15000),
    LaundryRecord('Sepatu', 'Cuci khusus', price: 25000),
  ];
  static final promos = <LaundryRecord>[
    LaundryRecord('Diskon 15%', 'Kupon pelanggan baru'),
    LaundryRecord('Diskon 10%', 'Kupon pelanggan setia'),
  ];
  static final orders = <LaundryRecord>[
    LaundryRecord('#AL-001', 'Cuci Setrika • 3 kg', price: 21000, status: 'Diproses'),
    LaundryRecord('#AL-002', 'Kemeja • 2 pcs', price: 30000, status: 'Menunggu'),
  ];
  static final payments = <LaundryRecord>[
    LaundryRecord('Pembayaran #AL-001', 'COD', price: 21000, status: 'Belum Lunas'),
    LaundryRecord('Pembayaran #AL-002', 'DANA', price: 30000, status: 'Lunas'),
  ];
  static final users = <LaundryRecord>[
    LaundryRecord('Pelanggan Demo A', 'pelanggan-a@example.com'),
    LaundryRecord('Pelanggan Demo B', 'pelanggan-b@example.com'),
  ];
  static final admins = <LaundryRecord>[
    LaundryRecord('Admin Demo', 'admin@example.com'),
  ];
  // Laporan yang dibuat Admin, tersimpan hanya selama aplikasi berjalan.
  static final reports = <LaundryReport>[];
  static bool notifications = true;
  static bool acceptingOrders = true;
}

class LaundryReport {
  LaundryReport({required this.title, required this.kind, required this.notes,
    required this.date, required this.total, required this.count});
  final String title, kind, notes;
  final DateTime date;
  final int total, count;
}

String laundryRupiah(int number) {
  final formatted = number.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.',
  );
  return 'Rp$formatted';
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int index = 0;
  final names = ['Beranda', 'Layanan', 'Pesanan', 'Lainnya'];
  @override
  Widget build(BuildContext context) => _DashboardShell(
    title: 'Admin AYO Laundry',
    selectedIndex: index,
    titles: names,
    onSelect: (value) => setState(() => index = value),
    onLogout: () => _logoutDashboard(context),
    child: switch (index) {
      0 => _AdminHome(onOpen: (value) => setState(() => index = value)),
      1 => _RecordEditor(title: 'Kelola Data Layanan', data: LaundryDemoStore.services, kind: 'service'),
      2 => _RecordEditor(title: 'Kelola Pesanan', data: LaundryDemoStore.orders, kind: 'order'),
      _ => _AdminMore(),
    },
  );
}

class OwnerPage extends StatefulWidget {
  const OwnerPage({super.key});
  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  int index = 0;
  final names = ['Beranda', 'Laporan', 'Admin', 'Pengaturan'];
  @override
  Widget build(BuildContext context) => _DashboardShell(
    title: 'Owner AYO Laundry',
    selectedIndex: index,
    titles: names,
    onSelect: (value) => setState(() => index = value),
    onLogout: () => _logoutDashboard(context),
    child: switch (index) {
      0 => _OwnerHome(onOpen: (value) => setState(() => index = value)),
      1 => const _OwnerReports(),
      2 => _RecordEditor(title: 'Kelola Data Admin', data: LaundryDemoStore.admins, kind: 'person'),
      _ => const _OwnerSettings(),
    },
  );
}

Future<void> _logoutDashboard(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Keluar dari akun?'),
      content: const Text('Sesi akun ini akan diakhiri.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await ApiService.logout();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

class _DashboardShell extends StatelessWidget {
  const _DashboardShell({required this.title, required this.child,
    required this.selectedIndex, required this.titles, required this.onSelect, required this.onLogout});
  final String title;
  final Widget child;
  final int selectedIndex;
  final List<String> titles;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) {
    const icons = [Icons.home_outlined, Icons.view_list_outlined,
      Icons.receipt_long_outlined, Icons.dashboard_customize_outlined];
    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: _LaundryDiagonalPainter())),
        SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Image.asset('assets/ayo_laundry.png', height: 42,
                  errorBuilder: (_, __, ___) => const Icon(Icons.local_laundry_service, color: _navy, size: 38)),
                const SizedBox(width: 12),
                Expanded(child: Text(title, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 17))),
                IconButton(onPressed: onLogout, icon: const Icon(Icons.logout, color: Colors.red),
                  tooltip: 'Logout', constraints: const BoxConstraints(minWidth: 40, minHeight: 40)),
              ]),
            ),
          ),
          Expanded(child: child),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(color: _yellow, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: NavigationBar(
              backgroundColor: _yellow,
              indicatorColor: Colors.white,
              height: 65,
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: List.generate(4, (i) => NavigationDestination(
                icon: Icon(icons[i]), label: titles[i],
              )),
            ),
          ),
        ])),
      ]),
    );
  }
}

class _LaundryDiagonalPainter extends CustomPainter {
  const _LaundryDiagonalPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _pageBg);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.9, 0)
      ..lineTo(0, size.height * 0.85)
      ..close();
    canvas.drawPath(path, Paint()..color = _yellow);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 16),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(color: _navy, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16))),
      Padding(padding: const EdgeInsets.all(12), child: child),
    ]),
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.title, required this.icon, required this.onTap, this.subtitle});
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(backgroundColor: const Color(0xFFFFF2BD), child: Icon(icon, color: _navy)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right), onTap: onTap,
  );
}

class _AdminHome extends StatelessWidget {
  const _AdminHome({required this.onOpen});
  final ValueChanged<int> onOpen;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Dashboard Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 14),
    _SectionCard(title: 'Ringkasan', child: Wrap(spacing: 12, runSpacing: 12, children: [
      _Metric('Layanan', '${LaundryDemoStore.services.length}', Icons.local_laundry_service_outlined),
      _Metric('Pesanan', '${LaundryDemoStore.orders.length}', Icons.receipt_outlined),
      _Metric('Pengguna', '${LaundryDemoStore.users.length}', Icons.people_outline),
    ])),
    _SectionCard(title: 'Manajemen', child: Column(children: [
      _MenuTile(title: 'Kelola Data Layanan', icon: Icons.local_laundry_service_outlined, onTap: () => onOpen(1)),
      _MenuTile(title: 'Kelola Harga', icon: Icons.price_change_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _RecordsPage(title: 'Kelola Harga Layanan', data: LaundryDemoStore.services, kind: 'service')))),
      _MenuTile(title: 'Kelola Pesanan', icon: Icons.receipt_long_outlined, onTap: () => onOpen(2)),
      _MenuTile(title: 'Kelola Promo & Kupon', icon: Icons.discount_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _RecordsPage(title: 'Kelola Promo & Kupon', data: LaundryDemoStore.promos, kind: 'promo')))),
      _MenuTile(title: 'Kelola Pembayaran', icon: Icons.payments_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _RecordsPage(title: 'Kelola Pembayaran', data: LaundryDemoStore.payments, kind: 'payment')))),
      _MenuTile(title: 'Kelola Pengguna', icon: Icons.people_outline,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerSearchPage()))),
      _MenuTile(title: 'Melihat & Membuat Laporan', icon: Icons.bar_chart_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AdminReportsPage()))),
    ])),
  ]);
}

class _AdminMore extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Menu Lainnya', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 14),
    _SectionCard(title: 'Administrasi', child: Column(children: [
      _MenuTile(title: 'Promo & Kupon', icon: Icons.discount_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _RecordsPage(title: 'Kelola Promo & Kupon', data: LaundryDemoStore.promos, kind: 'promo')))),
      _MenuTile(title: 'Pembayaran', icon: Icons.payments_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _RecordsPage(title: 'Kelola Pembayaran', data: LaundryDemoStore.payments, kind: 'payment')))),
      _MenuTile(title: 'Pengguna', icon: Icons.people_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerSearchPage()))),
      _MenuTile(title: 'Laporan', icon: Icons.bar_chart_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AdminReportsPage()))),
    ])),
  ]);
}

class _RecordsPage extends StatelessWidget {
  const _RecordsPage({required this.title, required this.data, required this.kind});
  final String title;
  final List<LaundryRecord> data;
  final String kind;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _pageBg,
    appBar: AppBar(backgroundColor: _yellow, title: Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
    body: _RecordEditor(title: title, data: data, kind: kind),
  );
}

class _RecordEditor extends StatefulWidget {
  const _RecordEditor({required this.title, required this.data, required this.kind});
  final String title;
  final List<LaundryRecord> data;
  final String kind;
  @override
  State<_RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<_RecordEditor> {
  Future<void> edit({LaundryRecord? record}) async {
    final name = TextEditingController(text: record?.name ?? '');
    final subtitle = TextEditingController(text: record?.subtitle ?? '');
    final price = TextEditingController(text: record == null ? '' : '${record.price}');
    final result = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(record == null ? 'Tambah Data' : 'Edit Data'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama / Judul')),
        TextField(controller: subtitle, decoration: const InputDecoration(labelText: 'Keterangan')),
        if (widget.kind == 'service' || widget.kind == 'order' || widget.kind == 'payment')
          TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga (rupiah)')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Simpan')),
      ],
    ));
    if (!mounted) return;
    if (result == true && name.text.trim().isNotEmpty) {
      setState(() {
        if (record == null) {
          widget.data.add(LaundryRecord(name.text.trim(), subtitle.text.trim(), price: int.tryParse(price.text) ?? 0));
        } else {
          record.name = name.text.trim();
          record.subtitle = subtitle.text.trim();
          record.price = int.tryParse(price.text) ?? record.price;
        }
      });
    }
    name.dispose(); subtitle.dispose(); price.dispose();
  }

  Future<void> remove(LaundryRecord record) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hapus data?'), content: Text('Hapus ${record.name}?'), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
    ]));
    if (yes == true && mounted) setState(() => widget.data.remove(record));
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Text(widget.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    _SectionCard(title: 'Daftar Data', child: Column(children: [
      for (final record in widget.data) ...[
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(record.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${record.subtitle}${record.price > 0 ? ' • ${laundryRupiah(record.price)}' : ''}\n${record.status}'),
          isThreeLine: true,
          trailing: Wrap(spacing: 0, children: [
            IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined, color: _navy), onPressed: () => edit(record: record)),
            IconButton(tooltip: 'Hapus', icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => remove(record)),
          ]),
          onTap: widget.kind == 'order' || widget.kind == 'payment' ? () async {
            final statuses = widget.kind == 'order'
              ? ['Menunggu', 'Diproses', 'Selesai', 'Dibatalkan']
              : ['Belum Lunas', 'Lunas', 'Dibatalkan'];
            final selected = await showModalBottomSheet<String>(context: context, builder: (ctx) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const ListTile(title: Text('Ubah Status')),
                ...statuses.map((s) => ListTile(title: Text(s), onTap: () => Navigator.pop(ctx, s))),
              ]),
            ));
            if (selected != null && mounted) setState(() => record.status = selected);
          } : null,
        ),
        const Divider(height: 1),
      ],
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: () => edit(),
        style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.black87),
        icon: const Icon(Icons.add), label: const Text('Tambah Data'),
      )),
    ])),
    const Text('MODE DEMO: perubahan belum disimpan ke MySQL dan akan hilang ketika aplikasi ditutup.',
      style: TextStyle(color: Colors.grey, fontSize: 12)),
  ]);
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 132, padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFFF3C6), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: _navy), const SizedBox(height: 7),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]),
  );
}

class _OwnerHome extends StatelessWidget {
  const _OwnerHome({required this.onOpen});
  final ValueChanged<int> onOpen;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Dashboard Owner', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 14),
    _SectionCard(title: 'Ringkasan Usaha (Data Demo)', child: Wrap(spacing: 12, runSpacing: 12, children: [
      _Metric('Pesanan', '${LaundryDemoStore.orders.length}', Icons.receipt_outlined),
      _Metric('Pembayaran Lunas', '${LaundryDemoStore.payments.where((p) => p.status == 'Lunas').length}', Icons.check_circle_outline),
      _Metric('Admin', '${LaundryDemoStore.admins.length}', Icons.admin_panel_settings_outlined),
    ])),
    _SectionCard(title: 'Menu Owner', child: Column(children: [
      _MenuTile(title: 'Melihat Laporan Penjualan', icon: Icons.trending_up, onTap: () => onOpen(1)),
      _MenuTile(title: 'Melihat Laporan Pesanan', icon: Icons.receipt_long_outlined, onTap: () => onOpen(1)),
      _MenuTile(title: 'Mengelola Data Admin', icon: Icons.admin_panel_settings_outlined, onTap: () => onOpen(2)),
      _MenuTile(title: 'Cari Data Pelanggan', icon: Icons.person_search_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerSearchPage()))),
    ])),
  ]);
}

class _AdminReportsPage extends StatefulWidget {
  const _AdminReportsPage();
  @override
  State<_AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<_AdminReportsPage> {
  Future<void> createReport() async {
    final title = TextEditingController();
    final notes = TextEditingController();
    String kind = 'Penjualan';
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
        title: const Text('Buat Laporan'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul laporan')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: kind, decoration: const InputDecoration(labelText: 'Jenis laporan'),
            items: ['Penjualan', 'Pesanan'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (value) { if (value != null) update(() => kind = value); }),
          const SizedBox(height: 12),
          TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () {
            if (title.text.trim().isEmpty) return;
            Navigator.pop(ctx, true);
          }, child: const Text('Buat')),
        ],
      )),
    );
    if (created == true && mounted) {
      final payments = LaundryDemoStore.payments.where((e) => e.status == 'Lunas');
      setState(() => LaundryDemoStore.reports.insert(0, LaundryReport(
        title: title.text.trim(), kind: kind, notes: notes.text.trim(), date: DateTime.now(),
        count: kind == 'Penjualan' ? payments.length : LaundryDemoStore.orders.length,
        total: kind == 'Penjualan' ? payments.fold<int>(0, (sum, e) => sum + e.price) : 0,
      )));
    }
    title.dispose();
    notes.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _pageBg,
    appBar: AppBar(title: const Text('Laporan Admin'), backgroundColor: _yellow),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      _SectionCard(title: 'Pembuatan Laporan', child: Column(children: [
        const Text('Buat laporan dari data demo pesanan atau pembayaran saat ini.'),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: createReport, icon: const Icon(Icons.add_chart),
          label: const Text('Buat Laporan Baru'),
          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.black),
        )),
      ])),
      _SectionCard(title: 'Laporan Tersimpan (Lokal)', child: Column(children: [
        if (LaundryDemoStore.reports.isEmpty) const Text('Belum ada laporan yang dibuat.'),
        for (final report in LaundryDemoStore.reports) ListTile(
          leading: const Icon(Icons.description_outlined, color: _navy),
          title: Text(report.title),
          subtitle: Text('${report.kind} • ${report.date.day}/${report.date.month}/${report.date.year}\n${report.notes}'),
          isThreeLine: true,
          trailing: IconButton(tooltip: 'Hapus laporan', icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => setState(() => LaundryDemoStore.reports.remove(report))),
          onTap: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
            title: Text(report.title),
            content: Text('Jenis: ${report.kind}\nJumlah: ${report.count}\nTotal: ${laundryRupiah(report.total)}\nCatatan: ${report.notes.isEmpty ? "-" : report.notes}'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
          )),
        ),
      ])),
      TextButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Ringkasan Laporan'), backgroundColor: _yellow),
          body: const _OwnerReports(),
        ))),
        icon: const Icon(Icons.visibility), label: const Text('Lihat Ringkasan Data Demo'),
      ),
    ]),
  );
}

class _OwnerReports extends StatelessWidget {
  const _OwnerReports();
  @override
  Widget build(BuildContext context) {
    final paid = LaundryDemoStore.payments.where((p) => p.status == 'Lunas').toList();
    final revenue = paid.fold<int>(0, (sum, p) => sum + p.price);
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Laporan AYO Laundry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      const SizedBox(height: 14),
      _SectionCard(title: 'Laporan Penjualan (Data Demo)', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(laundryRupiah(revenue), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const Text('Total pembayaran berstatus Lunas', style: TextStyle(color: Colors.grey)),
        const Divider(),
        ...paid.map((r) => ListTile(title: Text(r.name), subtitle: Text(r.subtitle), trailing: Text(laundryRupiah(r.price)))),
      ])),
      _SectionCard(title: 'Laporan Pesanan', child: Column(children: [
        ...LaundryDemoStore.orders.map((o) => ListTile(title: Text(o.name), subtitle: Text(o.subtitle), trailing: Text(o.status))),
        const Divider(),
        Text('Total: ${LaundryDemoStore.orders.length} pesanan'),
      ])),
      _SectionCard(title: 'Laporan yang Dibuat Admin', child: Column(children: [
        if (LaundryDemoStore.reports.isEmpty) const Text('Belum ada laporan dari Admin.'),
        ...LaundryDemoStore.reports.map((report) => ListTile(
          title: Text(report.title),
          subtitle: Text('${report.kind} • ${report.count} data • ${report.notes}'),
          trailing: Text(report.kind == 'Penjualan' ? laundryRupiah(report.total) : ''),
        )),
      ])),
      const Text('Laporan masih menggunakan data demo lokal, belum data transaksi MySQL.', style: TextStyle(color: Colors.grey, fontSize: 12)),
    ]);
  }
}

class _OwnerSettings extends StatefulWidget {
  const _OwnerSettings();
  @override
  State<_OwnerSettings> createState() => _OwnerSettingsState();
}

class _OwnerSettingsState extends State<_OwnerSettings> {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Pengaturan Sistem', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 14),
    _SectionCard(title: 'Konfigurasi (Demo)', child: Column(children: [
      SwitchListTile(title: const Text('Terima Pesanan'), subtitle: const Text('Aktifkan penerimaan pesanan baru'),
        activeThumbColor: _navy, value: LaundryDemoStore.acceptingOrders,
        onChanged: (v) => setState(() => LaundryDemoStore.acceptingOrders = v)),
      SwitchListTile(title: const Text('Notifikasi'), subtitle: const Text('Aktifkan notifikasi internal'),
        activeThumbColor: _navy, value: LaundryDemoStore.notifications,
        onChanged: (v) => setState(() => LaundryDemoStore.notifications = v)),
    ])),
    const Text('Pengaturan ini masih lokal; belum tersambung ke server MySQL.', style: TextStyle(color: Colors.grey, fontSize: 12)),
  ]);
}


// Pencarian real-time dari MySQL. Endpoint memeriksa token dan role di server.
class CustomerSearchPage extends StatefulWidget {
  const CustomerSearchPage({super.key});
  @override
  State<CustomerSearchPage> createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends State<CustomerSearchPage> {
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQuery(String input) {
    _debounce?.cancel();
    final requestId = ++_generation;
    if (input.trim().length < 2) {
      setState(() { _results = []; _error = null; _loading = false; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final data = await ApiService.searchCustomers(input);
        if (!mounted || requestId != _generation) return;
        setState(() { _results = data; _loading = false; });
      } catch (e) {
        if (!mounted || requestId != _generation) return;
        setState(() { _results = []; _error = '$e'; _loading = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _pageBg,
    appBar: AppBar(title: const Text('Cari Data Pelanggan'), backgroundColor: _yellow),
    body: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        Card(color: Colors.white, child: Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: _query,
            onChanged: _onQuery,
            decoration: InputDecoration(
              hintText: 'Nama, email, atau ID (min. 2 karakter)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () {
                _query.clear();
                _onQuery('');
              }),
            ),
          ),
        )),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_error!, style: const TextStyle(color: Colors.white)),
        ),
        Expanded(child: Card(color: Colors.white, child: ListView(
          children: [
            if (_query.text.trim().length < 2)
              const ListTile(title: Text('Ketik minimal 2 karakter untuk mencari pelanggan.')),
            if (!_loading && _error == null && _query.text.trim().length >= 2 && _results.isEmpty)
              const ListTile(title: Text('Tidak ada pelanggan ditemukan.')),
            ..._results.map((u) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(u['nama']?.toString() ?? '-'),
              subtitle: Text(u['email']?.toString() ?? '-'),
              trailing: Text('#${u['id'] ?? '-'}'),
            )),
          ],
        ))),
      ]),
    ),
  );
}
