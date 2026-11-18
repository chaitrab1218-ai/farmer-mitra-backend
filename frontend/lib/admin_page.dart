import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Module — Login + Fertilizer CRUD + Orders View
// Credentials: admin@gmail.com / Admin@123 (backend enforces)
// ─────────────────────────────────────────────────────────────────────────────

String get _adminApiBase => AppConfig.apiUrl;

// ══════════════════════════════════════════════════════════════════════════════
// Admin Service
// ══════════════════════════════════════════════════════════════════════════════
class AdminService {
  static String? _adminToken;
  static bool get isLoggedIn => _adminToken != null;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_adminToken ?? ""}',
      };

  // ── Login ──────────────────────────────────────────────────────────────────
  static Future<String?> login(String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_adminApiBase/api/admin/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        _adminToken = data['token'] as String?;
        return null; // success, no error
      }
      return data['message'] as String? ?? 'Login failed.';
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  static void logout() => _adminToken = null;

  // ── Fertilizers ────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchFertilizers() async {
    final res = await http.get(
      Uri.parse('$_adminApiBase/api/admin/fertilizers'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  static Future<String?> addFertilizer(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_adminApiBase/api/admin/fertilizers'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) return null;
    return data['message'] as String? ?? 'Failed to add.';
  }

  static Future<String?> updateFertilizer(int id, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$_adminApiBase/api/admin/fertilizers/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return null;
    return data['message'] as String? ?? 'Failed to update.';
  }

  static Future<String?> deleteFertilizer(int id) async {
    final res = await http.delete(
      Uri.parse('$_adminApiBase/api/admin/fertilizers/$id'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return null;
    return data['message'] as String? ?? 'Failed to delete.';
  }

  // ── Distributors ──────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchDistributors() async {
    final res = await http.get(
      Uri.parse('$_adminApiBase/api/admin/distributors'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  static Future<String?> addDistributor(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_adminApiBase/api/admin/distributors'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) return null;
    return data['message'] as String? ?? 'Failed to add distributor.';
  }

  static Future<String?> updateDistributor(int id, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$_adminApiBase/api/admin/distributors/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return null;
    return data['message'] as String? ?? 'Failed to update distributor.';
  }

  static Future<String?> deleteDistributor(int id) async {
    final res = await http.delete(
      Uri.parse('$_adminApiBase/api/admin/distributors/$id'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return null;
    return data['message'] as String? ?? 'Failed to delete distributor.';
  }

  // ── Orders ─────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchAllOrders() async {
    final res = await http.get(
      Uri.parse('$_adminApiBase/api/admin/orders'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  static Future<String?> cancelOrder(int id) async {
    final res = await http.put(
      Uri.parse('$_adminApiBase/api/admin/orders/$id/cancel'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return null;
    return data['message'] as String? ?? 'Failed to cancel order.';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Admin Login Page
// ══════════════════════════════════════════════════════════════════════════════
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailCtrl = TextEditingController(text: 'admin@gmail.com');
  final _passCtrl  = TextEditingController(text: 'Admin@123');
  bool _loading    = false;
  bool _obscure    = true;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error   = null;
    });
    final err = await AdminService.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: const Color(0xFF173D25),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.admin_panel_settings, size: 60, color: Color(0xFF237A3B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Krushi Mitra Admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF173D25)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF237A3B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Login as Admin', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Admin Shell — Tabs: Fertilizers | Orders | Profile
// ══════════════════════════════════════════════════════════════════════════════
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buf    = StringBuffer();
    bool quoted  = false;
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (quoted && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"'); i++;
        } else {
          quoted = !quoted;
        }
      } else if (c == ',' && !quoted) {
        result.add(buf.toString().trim()); buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString().trim());
    return result;
  }

  Future<void> _connectGoogleSheet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final distributors = await AdminService.fetchDistributors();
    if (!context.mounted) return;
    if (distributors.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please add at least one distributor before importing products.')),
      );
      return;
    }

    final ctrl = TextEditingController();
    int selectedDistId = distributors.first['id'] as int;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.table_chart, color: Color(0xFF237A3B)),
              SizedBox(width: 10),
              Text('Connect Google Sheet'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste your published Google Sheets CSV link to import fertilizers directly into Neon DB:',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Google Sheet CSV URL',
                  hintText: 'https://docs.google.com/.../pub?output=csv',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedDistId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Assign to Distributor *',
                  prefixIcon: Icon(Icons.storefront),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: distributors.map((d) {
                  return DropdownMenuItem<int>(
                    value: d['id'] as int,
                    child: Text(
                      '${d['name']} (${d['district']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedDistId = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF237A3B)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import Fertilizers'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      if (!context.mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Downloading Google Sheet CSV...')));

      try {
        final res = await http.get(Uri.parse(ctrl.text.trim())).timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          messenger.showSnackBar(SnackBar(content: Text('Failed to download sheet (HTTP ${res.statusCode})')));
          return;
        }

        final lines = const LineSplitter().convert(res.body).where((l) => l.trim().isNotEmpty).toList();
        if (lines.length < 2) {
          messenger.showSnackBar(const SnackBar(content: Text('Sheet is empty or has no data rows.')));
          return;
        }

        int importedCount = 0;
        // Skip header row
        for (int i = 1; i < lines.length; i++) {
          final cols = _parseCsvLine(lines[i]);
          if (cols.length < 5) continue;

          final body = {
            'distributor_id': selectedDistId,
            'name': cols[0],
            'category': cols.length > 1 ? cols[1] : 'General',
            'brand': cols.length > 2 ? cols[2] : 'Generic',
            'weight': cols.length > 3 ? cols[3] : '50 kg',
            'price': cols.length > 4 ? (double.tryParse(cols[4].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) : 0.0,
            'stock': cols.length > 8 ? (int.tryParse(cols[8].replaceAll(RegExp(r'[^0-9]'), '')) ?? 10) : 10,
          };

          final err = await AdminService.addFertilizer(body);
          if (err == null) importedCount++;
        }

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF237A3B),
            content: Text('Successfully imported $importedCount fertilizers from Google Sheet!'),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Error importing sheet: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF173D25),
          foregroundColor: Colors.white,
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.table_chart),
              tooltip: 'Connect Google Sheet',
              onPressed: () => _connectGoogleSheet(context),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.grass), text: 'Fertilizers'),
              Tab(icon: Icon(Icons.storefront), text: 'Distributors'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
              Tab(icon: Icon(Icons.person), text: 'Profile'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FertilizersTab(),
            _DistributorsTab(),
            _OrdersTab(),
            _AdminProfileTab(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Fertilizers Tab — CRUD
// ══════════════════════════════════════════════════════════════════════════════
class _FertilizersTab extends StatefulWidget {
  const _FertilizersTab();

  @override
  State<_FertilizersTab> createState() => _FertilizersTabState();
}

class _FertilizersTabState extends State<_FertilizersTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error   = null;
    });
    try {
      final data = await AdminService.fetchFertilizers();
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Fertilizer'),
        content: Text('Delete "${item['name']}" (${item['brand']})? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await AdminService.deleteFertilizer(item['id'] as int);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err')));
    } else {
      _load();
    }
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _FertilizerFormDialog(existing: item),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          itemCount: _items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final f = _items[i];
            final inStock = (f['stock'] as num? ?? 0) > 0;
            return Card(
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: inStock ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  child: Icon(
                    Icons.grass,
                    color: inStock ? const Color(0xFF237A3B) : Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  '${f['name']}  —  ${f['brand']}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  '${f['category']}  •  ${f['weight']}  •  ₹${f['price']}  •  Stock: ${f['stock']}\n'
                  '${f['distributor_name'] ?? f['shop'] ?? ''}${(f['distributor_district'] ?? f['district']) != null ? ", ${f['distributor_district'] ?? f['district']}" : ""}',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF237A3B)),
                      tooltip: 'Edit',
                      onPressed: () => _openForm(item: f),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _delete(f),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF237A3B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Fertilizer'),
        onPressed: () => _openForm(),
      ),
    );
  }
}

// ── Fertilizer Add/Edit Dialog ────────────────────────────────────────────────
class _FertilizerFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _FertilizerFormDialog({this.existing});

  @override
  State<_FertilizerFormDialog> createState() => _FertilizerFormDialogState();
}

class _FertilizerFormDialogState extends State<_FertilizerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _brand;
  late final TextEditingController _weight;
  late final TextEditingController _price;
  late final TextEditingController _stock;

  int? _selectedDistributorId;
  List<Map<String, dynamic>> _distributors = [];
  bool _loadingDistributors = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name     = TextEditingController(text: e?['name']     ?? '');
    _category = TextEditingController(text: e?['category'] ?? '');
    _brand    = TextEditingController(text: e?['brand']    ?? '');
    _weight   = TextEditingController(text: e?['weight']   ?? '');
    _price    = TextEditingController(text: e?['price']?.toString() ?? '');
    _stock    = TextEditingController(text: e?['stock']?.toString() ?? '0');
    _selectedDistributorId = e?['distributor_id'] as int?;
    _loadDistributors();
  }

  Future<void> _loadDistributors() async {
    try {
      final list = await AdminService.fetchDistributors();
      if (mounted) {
        setState(() {
          _distributors = list;
          _loadingDistributors = false;
          if (_selectedDistributorId == null && _distributors.isNotEmpty) {
            _selectedDistributorId = _distributors.first['id'] as int;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDistributors = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _category, _brand, _weight, _price, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDistributorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a distributor. Distributor is required.')),
      );
      return;
    }

    setState(() => _saving = true);
    final body = {
      'distributor_id': _selectedDistributorId,
      'name':     _name.text.trim(),
      'category': _category.text.trim(),
      'brand':    _brand.text.trim(),
      'weight':   _weight.text.trim(),
      'price':    double.tryParse(_price.text.trim()) ?? 0,
      'stock':    int.tryParse(_stock.text.trim()) ?? 0,
    };

    String? err;
    if (widget.existing != null) {
      err = await AdminService.updateFertilizer(widget.existing!['id'] as int, body);
    } else {
      err = await AdminService.addFertilizer(body);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err')));
    } else {
      Navigator.of(context).pop(true);
    }
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Fertilizer' : 'Add Fertilizer'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Mandatory Distributor Selector ──────────────────────────
                if (_loadingDistributors)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (_distributors.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: const Text(
                      'No distributors found! Please add a distributor in the Distributors tab first.',
                      style: TextStyle(color: Colors.brown, fontSize: 12),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedDistributorId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Distributor / Shop *',
                        prefixIcon: const Icon(Icons.storefront),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _distributors.map((d) {
                        return DropdownMenuItem<int>(
                          value: d['id'] as int,
                          child: Text(
                            '${d['name']} (${d['district']})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedDistributorId = val),
                      validator: (v) => v == null ? 'Distributor is required' : null,
                    ),
                  ),

                _field('Product Name *', _name),
                _field('Category * (e.g. Nitrogen, Organic)', _category),
                _field('Brand * (e.g. IFFCO, Coromandel)', _brand),
                _field('Weight * (e.g. 50 kg, 25 kg)', _weight),
                _field('Price (₹) *', _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                _field('Stock (quantity) *', _stock,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (int.tryParse(v.trim()) == null) return 'Enter a whole number';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF237A3B)),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Distributors Tab — Full Management (Add, Edit, Delete)
// ══════════════════════════════════════════════════════════════════════════════
class _DistributorsTab extends StatefulWidget {
  const _DistributorsTab();

  @override
  State<_DistributorsTab> createState() => _DistributorsTabState();
}

class _DistributorsTabState extends State<_DistributorsTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error   = null;
    });
    try {
      final data = await AdminService.fetchDistributors();
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _DistributorFormDialog(existing: item),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final count = item['fertilizer_count'] as int? ?? 0;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete "${item['name']}". It has $count fertilizers attached to it. Please reassign or delete them first.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Distributor'),
        content: Text('Delete "${item['name']}" (${item['district']})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await AdminService.deleteDistributor(item['id'] as int);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err')));
    } else {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          itemCount: _items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final d = _items[i];
            final count = d['fertilizer_count'] as int? ?? 0;
            return Card(
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: const Icon(Icons.storefront, color: Color(0xFF237A3B), size: 22),
                ),
                title: Text(
                  d['name'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      '${d['district']} • ${d['phone'] ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if ((d['address'] as String?)?.isNotEmpty == true)
                      Text(
                        d['address'] as String,
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF237A3B).withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$count Products Assigned',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF237A3B)),
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF237A3B)),
                      tooltip: 'Edit Distributor',
                      onPressed: () => _openForm(item: d),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Distributor',
                      onPressed: () => _delete(d),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF237A3B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: const Text('Add Distributor'),
        onPressed: () => _openForm(),
      ),
    );
  }
}

// ── Distributor Add/Edit Form Dialog ─────────────────────────────────────────
class _DistributorFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _DistributorFormDialog({this.existing});

  @override
  State<_DistributorFormDialog> createState() => _DistributorFormDialogState();
}

class _DistributorFormDialogState extends State<_DistributorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _district;
  late final TextEditingController _phone;
  late final TextEditingController _address;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name     = TextEditingController(text: e?['name']     ?? '');
    _district = TextEditingController(text: e?['district'] ?? '');
    _phone    = TextEditingController(text: e?['phone']    ?? '');
    _address  = TextEditingController(text: e?['address']  ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _district.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = {
      'name':     _name.text.trim(),
      'district': _district.text.trim(),
      'phone':    _phone.text.trim(),
      'address':  _address.text.trim(),
    };

    String? err;
    if (widget.existing != null) {
      err = await AdminService.updateDistributor(widget.existing!['id'] as int, body);
    } else {
      err = await AdminService.addDistributor(body);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err')));
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Distributor' : 'Add Distributor'),
      content: SizedBox(
        width: 340,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Distributor / Shop Name *',
                    prefixIcon: const Icon(Icons.storefront),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _district,
                  decoration: InputDecoration(
                    labelText: 'District * (e.g. Bengaluru)',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'District is required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Contact Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _address,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Shop / Warehouse Address',
                    prefixIcon: const Icon(Icons.map_outlined),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF237A3B)),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Orders Tab — View All Orders
// ══════════════════════════════════════════════════════════════════════════════
class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error   = null;
    });
    try {
      final data = await AdminService.fetchAllOrders();
      if (mounted) setState(() { _orders = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('No orders yet.', style: TextStyle(color: Colors.black54)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final o = _orders[i];
          final date = _fmt(o['created_at'] as String?);
          final status = (o['status'] as String? ?? 'placed').toUpperCase();
          final statusColor = switch (status) {
            'DELIVERED' => Colors.green,
            'CANCELLED' => Colors.red,
            _ => Colors.orange,
          };
          return Card(
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${o['fertilizer_name']}  •  ${o['brand'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _infoRow('Order ID', '#${o['id']}'),
                  _infoRow('Qty × Price', '${o['quantity']} ×  → ₹${o['total_price']}'),
                  _infoRow('Customer', o['customer_name'] ?? '—'),
                  _infoRow('Mobile', o['customer_mobile'] ?? '—'),
                  _infoRow('User Phone', o['user_phone'] ?? '—'),
                  _infoRow('Address', o['customer_address'] ?? '—'),
                  _infoRow('Date', date),
                  if (status != 'CANCELLED') ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancel Order'),
                              content: Text('Cancel order #${o['id']} (${o['fertilizer_name']})?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Cancel Order'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final err = await AdminService.cancelOrder(o['id'] as int);
                            if (mounted) {
                              if (err != null) {
                                messenger.showSnackBar(SnackBar(content: Text('Error: $err')));
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Order cancelled successfully.')),
                                );
                                _load();
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel Order', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text('$label:', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  String _fmt(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Admin Profile Tab — Account Details & Logout Button
// ══════════════════════════════════════════════════════════════════════════════
class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Admin Profile Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: const Icon(Icons.admin_panel_settings, size: 40, color: Color(0xFF237A3B)),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Administrator',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF173D25)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'admin@gmail.com',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF237A3B).withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Full Access',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF237A3B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // System Capabilities
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.storage, color: Color(0xFF237A3B)),
                title: const Text('Database Storage'),
                subtitle: const Text('Neon PostgreSQL (Cloud)'),
                trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Color(0xFF237A3B)),
                title: const Text('Google Sheets Sync'),
                subtitle: const Text('Connect CSV URL from Top Bar'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security, color: Color(0xFF237A3B)),
                title: const Text('Authentication Mode'),
                subtitle: const Text('JWT Protected Admin Session'),
                trailing: const Icon(Icons.lock, size: 18, color: Colors.grey),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        // ── Logout Button on Admin Profile Page ───────────────────────────────
        Center(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Admin Logout'),
                  content: const Text('Are you sure you want to log out from the Admin Panel?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                AdminService.logout();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            icon: const Icon(Icons.logout, size: 20),
            label: const Text(
              'Log Out as Admin',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
