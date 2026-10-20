import 'package:flutter/material.dart';

// AYO Laundry - Dashboard Admin dan Owner (prototipe UI / data lokal).
// Tambahkan file ini ke lib/admin_owner_pages.dart, lalu import di main.dart.
const _yellow = Color(0xFFFFD54F);
const _navy = Color(0xFF2C3E50);
const _pageBg = Color(0xFFF3F1F7);

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
  static bool notifications = true;
  static bool acceptingOrders = true;
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
    child: switch (index) {
      0 => _AdminHome(onOpen: (value) => setState(() => index = value)),
      1 => _RecordEditor(title: 'Kelola Data Layanan & Harga', data: LaundryDemoStore.services, kind: 'service'),
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
    child: switch (index) {
      0 => _OwnerHome(onOpen: (value) => setState(() => index = value)),
      1 => const _OwnerReports(),
      2 => _RecordEditor(title: 'Kelola Data Admin', data: LaundryDemoStore.admins, kind: 'person'),
      _ => const _OwnerSettings(),
    },
  );
}

class _DashboardShell extends StatelessWidget {
  const _DashboardShell({required this.title, required this.child,
    required this.selectedIndex, required this.titles, required this.onSelect});
  final String title;
  final Widget child;
  final int selectedIndex;
  final List<String> titles;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    const icons = [Icons.home_outlined, Icons.view_list_outlined,
      Icons.receipt_long_outlined, Icons.dashboard_customize_outlined];
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _yellow,
        centerTitle: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 19)),
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(color: _yellow, borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
          child: NavigationBar(
            backgroundColor: _yellow,
            indicatorColor: Colors.white70,
            height: 68,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelect,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: List.generate(4, (i) => NavigationDestination(
              icon: Icon(icons[i]), label: titles[i],
            )),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFF9F7FC),
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
      _MenuTile(title: 'Kelola Data Layanan & Harga', icon: Icons.local_laundry_service_outlined, onTap: () => onOpen(1)),
      _MenuTile(title: 'Kelola Pesanan', icon: Icons.receipt_long_outlined, onTap: () => onOpen(2)),
      _MenuTile(title: 'Kelola Promo & Kupon', icon: Icons.discount_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _RecordsPage(title: 'Kelola Promo & Kupon', data: LaundryDemoStore.promos, kind: 'promo')))),
      _MenuTile(title: 'Kelola Pembayaran', icon: Icons.payments_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _RecordsPage(title: 'Kelola Pembayaran', data: LaundryDemoStore.payments, kind: 'payment')))),
      _MenuTile(title: 'Kelola Pengguna', icon: Icons.people_outline,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _RecordsPage(title: 'Kelola Pengguna', data: LaundryDemoStore.users, kind: 'person')))),
      _MenuTile(title: 'Melihat Laporan', icon: Icons.bar_chart_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SimpleReports()))),
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
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _RecordsPage(title: 'Kelola Pengguna', data: LaundryDemoStore.users, kind: 'person')))),
      _MenuTile(title: 'Laporan', icon: Icons.bar_chart_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SimpleReports()))),
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
          trailing: Wrap(mainAxisSize: MainAxisSize.min, spacing: 0, children: [
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
        style: ElevatedButton.styleFrom(backgroundColor: _yellow, foregroundColor: Colors.black87),
        icon: const Icon(Icons.add), label: const Text('Tambah Data'),
      )),
    ])),
    const Text('Mode demo: perubahan hanya tersimpan selama aplikasi berjalan.',
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
      _MenuTile(title: 'Pengaturan Sistem', icon: Icons.settings_outlined, onTap: () => onOpen(3)),
    ])),
  ]);
}

class _SimpleReports extends StatelessWidget {
  const _SimpleReports();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _pageBg,
    appBar: AppBar(title: const Text('Laporan Admin'), backgroundColor: _yellow),
    body: const _OwnerReports(),
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
      const Text('Laporan masih menggunakan data lokal, belum data transaksi Firebase.', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
    const Text('Belum mengubah konfigurasi server Firebase.', style: TextStyle(color: Colors.grey, fontSize: 12)),
  ]);
}
