import 'dart:async';
import 'package:flutter/material.dart';
import 'services/api_service.dart';

const _adminYellow = Color(0xFFFFD54F);
const _adminNavy = Color(0xFF2C3E50);
const _adminBlue = Color(0xFF2196F3);

String _money(dynamic value) {
  final number = int.tryParse(value.toString()) ?? 0;
  return 'Rp${number.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
}

int _asInt(dynamic value) => int.tryParse(value.toString()) ?? 0;

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});
  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  Timer? _timer;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _notifications = [];
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getAdminOrders(),
        ApiService.getAdminNotifications(),
      ]);
      if (!mounted) return;
      final noteData = results[1] as Map<String, dynamic>;
      setState(() {
        _orders = results[0] as List<Map<String, dynamic>>;
        _notifications = (noteData['notifications'] as List? ?? [])
            .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _unread = _asInt(noteData['unread_count']);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await ApiService.markNotificationRead(id);
      await _load(silent: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _changeStatus(int id, String status) async {
    try {
      await ApiService.updateAdminOrderStatus(id, status);
      await _load(silent: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status pesanan diperbarui.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _markCodPaid(int id) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Konfirmasi pembayaran COD'),
      content: const Text('Pastikan uang benar-benar sudah diterima sebelum menandai pembayaran sebagai lunas.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, sudah diterima')),
      ],
    ));
    if (yes != true) return;
    try {
      await ApiService.markCodPaid(id);
      await _load(silent: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Widget _notificationCard(Map<String, dynamic> n) {
    final id = _asInt(n['id']);
    final isRead = _asInt(n['is_read']) == 1 || n['is_read'] == true;
    return Card(
      color: isRead ? Colors.white : const Color(0xFFFFF8DC),
      child: ListTile(
        leading: Icon(isRead ? Icons.notifications_none : Icons.notifications_active, color: _adminNavy),
        title: Text(n['title']?.toString() ?? 'Notifikasi', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(n['message']?.toString() ?? ''),
        trailing: isRead ? const Icon(Icons.done, color: Colors.green) : TextButton(onPressed: () => _markRead(id), child: const Text('Dibaca')),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final id = _asInt(order['id']);
    final status = order['order_status']?.toString() ?? 'menunggu_konfirmasi';
    final payStatus = order['payment_status']?.toString() ?? 'pending';
    final method = order['payment_method']?.toString() ?? '-';
    final items = (order['items'] as List? ?? []).whereType<Map>().toList();
    const statuses = ['menunggu_pembayaran', 'menunggu_konfirmasi', 'dikonfirmasi', 'diproses', 'siap_diambil', 'selesai', 'dibatalkan'];
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(order['order_code']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFFFF2BD), borderRadius: BorderRadius.circular(20)), child: Text(status.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 6),
          Text('${order['customer_name'] ?? '-'} • ${order['email'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text('Alamat: ${order['customer_address'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const Divider(height: 18),
          for (final item in items)
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
              Expanded(child: Text('${item['service_name']} • ${item['quantity']} ${item['unit_label']}', style: const TextStyle(fontSize: 12))),
              Text(_money(item['line_total']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ])),
          const Divider(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Metode: $method • Pembayaran: $payStatus', style: const TextStyle(fontSize: 11, color: Colors.black54)),
            Text(_money(order['total_amount']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            SizedBox(width: 190, child: DropdownButtonFormField<String>(
              value: statuses.contains(status) ? status : statuses.first,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ubah status', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (value) { if (value != null && value != status) _changeStatus(id, value); },
            )),
            if (method == 'COD' && payStatus == 'unpaid')
              OutlinedButton.icon(onPressed: () => _markCodPaid(id), icon: const Icon(Icons.payments_outlined), label: const Text('Tandai COD lunas')),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF2196F3),
    appBar: AppBar(
      title: const Text('Pesanan & Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: _adminYellow,
      actions: [
        Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('Baru: $_unread', style: const TextStyle(fontWeight: FontWeight.bold)))),
        IconButton(onPressed: () => _load(), icon: const Icon(Icons.refresh)),
      ],
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : _error != null
        ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Coba lagi', style: TextStyle(color: Colors.white))),
          ])))
        : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
              const Expanded(child: Text('Notifikasi pesanan baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              if (_unread > 0) Chip(label: Text('$_unread belum dibaca'), backgroundColor: const Color(0xFFFFF2BD)),
              TextButton(onPressed: () async {
                try { await ApiService.markAllNotificationsRead(); await _load(silent: true); }
                catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
              }, child: const Text('Baca semua')),
            ]))),
            if (_notifications.isEmpty) const Card(child: ListTile(title: Text('Belum ada notifikasi.'))),
            for (final n in _notifications.take(10)) _notificationCard(n),
            const SizedBox(height: 10),
            const Text('Pesanan pelanggan', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_orders.isEmpty) const Card(child: ListTile(title: Text('Belum ada pesanan masuk.'))),
            for (final order in _orders) _orderCard(order),
            const SizedBox(height: 20),
          ])),
  );
}

class AdminServicesPage extends StatefulWidget {
  const AdminServicesPage({super.key});
  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends State<AdminServicesPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
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

  Future<void> _edit(Map<String, dynamic> service) async {
    final controller = TextEditingController(text: '${service['unit_price']}');
    bool active = (service['is_active']?.toString() ?? '1') == '1';
    final result = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
      title: Text('Edit ${service['name']}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga per satuan (Rp)')),
        SwitchListTile(value: active, onChanged: (v) => update(() => active = v), title: const Text('Layanan aktif')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan'))],
    )));
    if (result == true) {
      final price = int.tryParse(controller.text);
      if (price == null || price < 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga tidak valid.')));
      } else {
        try {
          await ApiService.updateService(id: _asInt(service['id']), price: price, active: active);
          await _load();
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _adminBlue,
    appBar: AppBar(title: const Text('Kelola Layanan & Harga'), backgroundColor: _adminYellow, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white)))
      : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
          for (final service in _services) Card(color: Colors.white, child: ListTile(
            title: Text(service['name']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${service['category']} • ${_money(service['unit_price'])}/${service['unit_label']} • ${service['is_active'].toString() == '1' ? 'Aktif' : 'Nonaktif'}'),
            trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(service)),
          )),
        ])),
  );
}

class AdminPromosPage extends StatefulWidget {
  const AdminPromosPage({super.key});
  @override
  State<AdminPromosPage> createState() => _AdminPromosPageState();
}

class _AdminPromosPageState extends State<AdminPromosPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _promos = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getAdminPromos();
      if (!mounted) return;
      setState(() { _promos = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _create() async {
    final code = TextEditingController();
    final title = TextEditingController();
    final desc = TextEditingController();
    final value = TextEditingController(text: '10');
    final minimum = TextEditingController(text: '20000');
    final max = TextEditingController();
    final usage = TextEditingController();
    String type = 'percent';
    final result = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
      title: const Text('Buat Promo Baru'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: code, decoration: const InputDecoration(labelText: 'Kode promo')),
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul promo')),
        TextField(controller: desc, decoration: const InputDecoration(labelText: 'Deskripsi')),
        DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Jenis diskon'),
          items: const [DropdownMenuItem(value: 'percent', child: Text('Persentase (%)')), DropdownMenuItem(value: 'fixed', child: Text('Nominal (Rp)'))],
          onChanged: (v) { if (v != null) update(() => type = v); }),
        TextField(controller: value, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: type == 'percent' ? 'Diskon (%)' : 'Diskon (Rp)')),
        TextField(controller: minimum, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minimum transaksi (Rp)')),
        TextField(controller: max, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Maksimum potongan (opsional)')),
        TextField(controller: usage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Batas penggunaan (opsional)')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buat Promo'))],
    )));
    if (result == true) {
      try {
        await ApiService.createPromo(code: code.text.trim(), title: title.text.trim(), description: desc.text.trim(),
          discountType: type, discountValue: int.parse(value.text), minSubtotal: int.parse(minimum.text),
          maxDiscount: max.text.trim().isEmpty ? null : int.parse(max.text),
          usageLimit: usage.text.trim().isEmpty ? null : int.parse(usage.text));
        await _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
    code.dispose(); title.dispose(); desc.dispose(); value.dispose(); minimum.dispose(); max.dispose(); usage.dispose();
  }

  Future<void> _toggle(Map<String, dynamic> promo) async {
    final active = (promo['is_active']?.toString() ?? '1') == '1';
    try {
      await ApiService.togglePromo(id: _asInt(promo['id']), active: !active);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _adminBlue,
    appBar: AppBar(title: const Text('Kelola Promo & Kupon'), backgroundColor: _adminYellow,
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: _create, backgroundColor: const Color(0xFF76FF03), foregroundColor: Colors.black,
      icon: const Icon(Icons.add), label: const Text('Buat Promo')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white)))
      : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(16,16,16,90), children: [
          if (_promos.isEmpty) const Card(child: ListTile(title: Text('Belum ada promo.'))),
          for (final promo in _promos) Card(color: Colors.white, child: ListTile(
            title: Text('${promo['title']} (${promo['code']})', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${promo['discount_type'] == 'percent' ? '${promo['discount_value']}%' : _money(promo['discount_value'])} • Min ${_money(promo['min_subtotal'])} • Terpakai ${promo['usage_count']}/${promo['usage_limit'] ?? '∞'}'),
            trailing: Switch(value: (promo['is_active']?.toString() ?? '1') == '1', onChanged: (_) => _toggle(promo)),
          )),
        ])),
  );
}
