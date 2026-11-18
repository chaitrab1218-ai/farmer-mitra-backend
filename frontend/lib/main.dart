import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'login_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — no Firebase
// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore saved Neon Auth session on cold start
  await NeonAuthService.loadFromStorage();
  runApp(const KrushiMitraApp());
}

class KrushiMitraApp extends StatelessWidget {
  const KrushiMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krushi Mitra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF237A3B)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F8F3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF173D25),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// Kept for test compatibility
typedef MyApp = KrushiMitraApp;

// ── Auth gate ─────────────────────────────────────────────────────────────────
// NeonAuthService is NOT a stream — we use a ValueNotifier-based approach.
// The gate rebuilds whenever the auth state changes.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Listen for auth changes published by the service
    NeonAuthService.addListener(_onAuthChange);
  }

  @override
  void dispose() {
    NeonAuthService.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return NeonAuthService.isLoggedIn ? const MainShell() : const LoginPage();
  }
}

// Backend Express API base
// Works on Web, Windows Desktop, and USB-connected Android phones via adb reverse.
const String _kApiBase = 'http://localhost:5000';

// ─────────────────────────────────────────────────────────────────────────────
// API service — attaches Neon Auth JWT to every request
// ─────────────────────────────────────────────────────────────────────────────
class ApiService {
  static const _timeout = Duration(seconds: 15);

  static Future<List<FertilizerOffer>?> fetchFertilizers({
    String query = '',
    String category = 'all',
  }) async {
    try {
      final uri = Uri.parse('$_kApiBase/api/fertilizers').replace(
        queryParameters: {
          if (query.isNotEmpty) 'q': query,
          if (category.isNotEmpty && category.toLowerCase() != 'all')
            'category': category.toLowerCase(),
        },
      );
      final response =
          await http.get(uri, headers: NeonAuthService.authHeaders).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      final data = body['data'] as List<dynamic>;
      return data
          .map((e) => FertilizerOffer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> placeOrder({
    required int? fertilizerId,
    required String fertilizerName,
    required String brand,
    required int quantity,
    required double totalPrice,
    required String customerName,
    required String customerMobile,
    required String customerAddress,
  }) async {
    try {
      // 1 — dummy payment create-order
      await http
          .post(
            Uri.parse('$_kApiBase/api/payments/create-order'),
            headers: NeonAuthService.authHeaders,
            body: jsonEncode({'amount': totalPrice}),
          )
          .timeout(_timeout);

      // 2 — dummy payment verify
      await http
          .post(
            Uri.parse('$_kApiBase/api/payments/verify'),
            headers: NeonAuthService.authHeaders,
            body: jsonEncode({'isDummy': true}),
          )
          .timeout(_timeout);

      // 3 — save order in Neon DB (protected route)
      final saveRes = await http
          .post(
            Uri.parse('$_kApiBase/api/orders'),
            headers: NeonAuthService.authHeaders,
            body: jsonEncode({
              'fertilizer_id':     fertilizerId,
              'fertilizer_name':   fertilizerName,
              'brand':             brand,
              'quantity':          quantity,
              'total_price':       totalPrice,
              'customer_name':     customerName,
              'customer_mobile':   customerMobile,
              'customer_address':  customerAddress,
            }),
          )
          .timeout(_timeout);

      if (saveRes.statusCode != 200) return null;
      final saved = jsonDecode(saveRes.body) as Map<String, dynamic>;
      return saved['order'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final res = await http
          .get(Uri.parse('$_kApiBase/api/auth/profile'),
              headers: NeonAuthService.authHeaders)
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> cancelOrder(int orderId) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_kApiBase/api/orders/$orderId/cancel'),
            headers: NeonAuthService.authHeaders,
          )
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class FertilizerOffer {
  final int? id;
  final String name;
  final String category;
  final String brand;
  final String weight;
  final double price;
  final String shop;
  final String district;
  final String phone;
  final int stock;
  final String updated;
  final String? distributorName;
  final String? distributorDistrict;

  const FertilizerOffer({
    this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.weight,
    required this.price,
    required this.shop,
    required this.district,
    required this.phone,
    required this.stock,
    required this.updated,
    this.distributorName,
    this.distributorDistrict,
  });

  /// Returns the display shop label: prefers distributor name, falls back to shop field.
  String get shopLabel => distributorName?.isNotEmpty == true ? distributorName! : shop;
  /// Returns the display district: prefers distributor district, falls back to district field.
  String get districtLabel => distributorDistrict?.isNotEmpty == true ? distributorDistrict! : district;

  factory FertilizerOffer.fromJson(Map<String, dynamic> j) => FertilizerOffer(
        id:                 j['id'] as int?,
        name:               (j['name']                as String?) ?? '',
        category:           (j['category']            as String?) ?? '',
        brand:              (j['brand']               as String?) ?? '',
        weight:             (j['weight']              as String?) ?? '',
        price:              double.tryParse(j['price']?.toString() ?? '0') ?? 0,
        shop:               (j['shop']                as String?) ?? '',
        district:           (j['district']            as String?) ?? '',
        phone:              (j['phone']               as String?) ?? '',
        stock:              (j['stock']               as int?)    ?? 0,
        updated:            (j['updated']             as String?) ?? '',
        distributorName:    (j['distributor_name']    as String?),
        distributorDistrict:(j['distributor_district'] as String?),
      );

  factory FertilizerOffer.fromCsv(List<String> c) => FertilizerOffer(
        name:     _at(c, 1),
        category: _at(c, 2),
        brand:    _at(c, 3),
        weight:   _at(c, 4),
        price:    double.tryParse(_at(c, 5).replaceAll(',', '').replaceAll('₹', '')) ?? 0,
        shop:     _at(c, 6),
        district: _at(c, 7),
        phone:    _at(c, 8),
        stock:    int.tryParse(_at(c, 9)) ?? 0,
        updated:  _at(c, 10),
      );

  static String _at(List<String> c, int i) => i < c.length ? c[i].trim() : '';
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback demo data (shown when backend is unreachable)
// ─────────────────────────────────────────────────────────────────────────────
const demoOffers = <FertilizerOffer>[
  FertilizerOffer(name: 'Urea',               category: 'Nitrogen',       brand: 'IFFCO',      weight: '45 kg', price: 266.50, shop: 'Demo Agro Centre',   district: 'Bengaluru', phone: '', stock: 20, updated: 'Sample'),
  FertilizerOffer(name: 'Urea',               category: 'Nitrogen',       brand: 'KRIBHCO',    weight: '45 kg', price: 268,    shop: 'Demo Farmers Store', district: 'Bengaluru', phone: '', stock: 12, updated: 'Sample'),
  FertilizerOffer(name: 'DAP',                category: 'Phosphatic',     brand: 'IFFCO',      weight: '50 kg', price: 1350,   shop: 'Demo Agro Centre',   district: 'Bengaluru', phone: '', stock: 8,  updated: 'Sample'),
  FertilizerOffer(name: 'DAP',                category: 'Phosphatic',     brand: 'Coromandel', weight: '50 kg', price: 1380,   shop: 'Demo Farmers Store', district: 'Bengaluru', phone: '', stock: 0,  updated: 'Sample'),
  FertilizerOffer(name: 'MOP',                category: 'Potassic',       brand: 'IPL',        weight: '50 kg', price: 1700,   shop: 'Demo Agro Centre',   district: 'Bengaluru', phone: '', stock: 15, updated: 'Sample'),
  FertilizerOffer(name: 'NPK 10:26:26',       category: 'Complex',        brand: 'Coromandel', weight: '50 kg', price: 1500,   shop: 'Demo Agro Centre',   district: 'Bengaluru', phone: '', stock: 10, updated: 'Sample'),
  FertilizerOffer(name: 'NPK 12:32:16',       category: 'Complex',        brand: 'IFFCO',      weight: '50 kg', price: 1475,   shop: 'Demo Farmers Store', district: 'Bengaluru', phone: '', stock: 7,  updated: 'Sample'),
  FertilizerOffer(name: 'NPK 19:19:19',       category: 'Water Soluble',  brand: 'IFFCO',      weight: '25 kg', price: 1400,   shop: 'Demo Agro Centre',   district: 'Bengaluru', phone: '', stock: 5,  updated: 'Sample'),
  FertilizerOffer(name: 'SSP',                category: 'Phosphatic',     brand: 'FACT',       weight: '50 kg', price: 520,    shop: 'Demo Farmers Store', district: 'Bengaluru', phone: '', stock: 18, updated: 'Sample'),
  FertilizerOffer(name: 'Ammonium Sulphate',  category: 'Nitrogen',       brand: 'FACT',       weight: '50 kg', price: 700,    shop: 'Demo Agro Centre',   district: 'Bengaluru', phone: '', stock: 9,  updated: 'Sample'),
  FertilizerOffer(name: 'SOP',                category: 'Potassic',       brand: 'Coromandel', weight: '25 kg', price: 1450,   shop: 'Demo Farmers Store', district: 'Bengaluru', phone: '', stock: 4,  updated: 'Sample'),
  FertilizerOffer(name: 'Zinc Sulphate',      category: 'Micronutrients', brand: 'Multiplex',  weight: '5 kg',  price: 450,    shop: 'Demo Agro Centre',   district: 'Bengaluru', phone: '', stock: 11, updated: 'Sample'),
  FertilizerOffer(name: 'Boron',              category: 'Micronutrients', brand: 'Multiplex',  weight: '1 kg',  price: 320,    shop: 'Demo Farmers Store', district: 'Bengaluru', phone: '', stock: 6,  updated: 'Sample'),
  FertilizerOffer(name: 'Magnesium Sulphate', category: 'Micronutrients', brand: 'Multiplex',  weight: '25 kg', price: 650,    shop: 'Demo Agro Centre',   district: 'Bengaluru', phone: '', stock: 13, updated: 'Sample'),
  FertilizerOffer(name: 'Ferrous Sulphate',   category: 'Micronutrients', brand: 'Generic',    weight: '5 kg',  price: 280,    shop: 'Demo Farmers Store', district: 'Bengaluru', phone: '', stock: 3,  updated: 'Sample'),
  FertilizerOffer(name: 'Vermicompost',       category: 'Organic',        brand: 'Local',      weight: '25 kg', price: 250,    shop: 'Demo Agro Centre',   district: 'Bengaluru', phone: '', stock: 30, updated: 'Sample'),
  FertilizerOffer(name: 'Neem Cake',          category: 'Organic',        brand: 'Local',      weight: '25 kg', price: 500,    shop: 'Demo Farmers Store', district: 'Bengaluru', phone: '', stock: 14, updated: 'Sample'),
  FertilizerOffer(name: 'Rhizobium Biofertilizer', category: 'Biofertilizer', brand: 'Bio-input', weight: '1 kg', price: 180, shop: 'Demo Agro Centre',   district: 'Bengaluru', phone: '', stock: 16, updated: 'Sample'),
  FertilizerOffer(name: 'PSB Biofertilizer',  category: 'Biofertilizer',  brand: 'Bio-input',  weight: '1 kg',  price: 190,    shop: 'Demo Farmers Store', district: 'Bengaluru', phone: '', stock: 0,  updated: 'Sample'),
  FertilizerOffer(name: 'Calcium Nitrate',    category: 'Water Soluble',  brand: 'Generic',    weight: '25 kg', price: 1250,   shop: 'Demo Agro Centre',   district: 'Bengaluru', phone: '', stock: 5,  updated: 'Sample'),
];

// ─────────────────────────────────────────────────────────────────────────────
// MainShell
// ─────────────────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int    tab      = 0;
  String query    = '';
  String category = 'All';
  bool   kannada  = false;
  bool   loading  = false;

  String? sheetUrl;
  String  sourceMessage = 'Connecting to Krushi Mitra server…';

  List<FertilizerOffer> offers = List.of(demoOffers);
  final List<FertilizerOffer> cart = [];

  int compareIndex1 = 0;
  int compareIndex2 = 1;

  static const categories = [
    'All', 'Nitrogen', 'Phosphatic', 'Potassic', 'Complex',
    'Water Soluble', 'Micronutrients', 'Organic', 'Biofertilizer',
  ];

  String t(String en, String kn) => kannada ? kn : en;

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchFromApi();
    _loadSheet();
  }

  // ── backend fetch ─────────────────────────────────────────────────────────
  Future<void> _fetchFromApi() async {
    if (!mounted) return;
    setState(() => loading = true);
    final result = await ApiService.fetchFertilizers();
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      setState(() {
        offers        = result;
        sourceMessage = 'Live data from Krushi Mitra server • ${result.length} offers';
        loading       = false;
      });
    } else {
      setState(() {
        sourceMessage = 'Server unreachable — showing sample data.';
        loading       = false;
      });
    }
  }

  // ── Google Sheet CSV (optional override) ──────────────────────────────────
  Future<void> _loadSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final url   = prefs.getString('sheet_csv_url');
    if (url != null && url.isNotEmpty) {
      sheetUrl = url;
      await _refreshSheet();
    }
  }

  Future<void> _refreshSheet() async {
    if (sheetUrl == null || sheetUrl!.isEmpty) return;
    if (mounted) setState(() => loading = true);
    try {
      final response = await http
          .get(Uri.parse(sheetUrl!))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final lines = response.body
          .replaceFirst('\uFEFF', '')
          .split(RegExp(r'\r?\n'))
          .where((e) => e.trim().isNotEmpty)
          .toList();
      if (lines.length < 2) throw Exception('Sheet is empty');

      final parsed = <FertilizerOffer>[];
      for (final line in lines.skip(1)) {
        final cells = _parseCsv(line);
        if (cells.length >= 6 && cells[1].trim().isNotEmpty) {
          parsed.add(FertilizerOffer.fromCsv(cells));
        }
      }
      if (parsed.isEmpty) throw Exception('No valid rows found.');

      if (mounted) {
        setState(() {
          offers        = parsed;
          sourceMessage = 'Google Sheets • ${parsed.length} offers loaded.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => sourceMessage = 'Sheet error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<String> _parseCsv(String line) {
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
        result.add(buf.toString()); buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString());
    return result;
  }

  List<FertilizerOffer> get filtered {
    final search = query.toLowerCase().trim();
    return offers.where((o) {
      final catOk    = category == 'All' || o.category == category;
      final searchOk = search.isEmpty ||
          '${o.name} ${o.brand} ${o.category} ${o.shopLabel} ${o.districtLabel}'
              .toLowerCase()
              .contains(search);
      return catOk && searchOk;
    }).toList();
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _compare(), _shops(), _cart(), _profile()];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.eco, color: Color(0xFF278345)),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Krushi Mitra', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Color(0xFF278345)),
            tooltip: t('Change Language', 'ಭಾಷೆ ಬದಲಾಯಿಸಿ'),
            onSelected: (String lang) {
              setState(() => kannada = (lang == 'kn'));
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    Text('English',
                        style: TextStyle(
                            fontWeight: !kannada ? FontWeight.bold : FontWeight.normal)),
                    if (!kannada) ...[
                      const Spacer(),
                      const Icon(Icons.check, color: Color(0xFF278345), size: 18),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'kn',
                child: Row(
                  children: [
                    Text('ಕನ್ನಡ (Kannada)',
                        style: TextStyle(
                            fontWeight: kannada ? FontWeight.bold : FontWeight.normal)),
                    if (kannada) ...[
                      const Spacer(),
                      const Icon(Icons.check, color: Color(0xFF278345), size: 18),
                    ],
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: t('Refresh from server', 'Server ನಿಂದ Refresh'),
            onPressed: loading ? null : _fetchFromApi,
            icon: loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined),         selectedIcon: const Icon(Icons.home),              label: t('Home', 'ಮುಖಪುಟ')),
          NavigationDestination(icon: const Icon(Icons.compare_arrows_outlined),selectedIcon: const Icon(Icons.compare_arrows),    label: t('Compare', 'ಹೋಲಿಸಿ')),
          NavigationDestination(icon: const Icon(Icons.storefront_outlined),   selectedIcon: const Icon(Icons.storefront),        label: t('Shops', 'ಅಂಗಡಿಗಳು')),
          NavigationDestination(icon: const Icon(Icons.shopping_cart_outlined), selectedIcon: const Icon(Icons.shopping_cart),    label: t('Cart', 'ಕಾರ್ಟ್')),
          NavigationDestination(icon: const Icon(Icons.person_outline),         selectedIcon: const Icon(Icons.person),           label: t('Profile', 'ಪ್ರೊಫೈಲ್')),
        ],
      ),
    );
  }

  // ─────────────────────────── Home tab ────────────────────────────────────
  Widget _home() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // hero banner
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [Color(0xFF1D7139), Color(0xFF56A65E)]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('Grow better, spend smarter', 'ಉತ್ತಮವಾಗಿ ಬೆಳೆಸಿ, ಬುದ್ಧಿವಂತಿಕೆಯಿಂದ ಖರ್ಚು ಮಾಡಿ'),
              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(t('Find fertilizers • Compare shop prices • Check stock',
                 'ರಸಗೊಬ್ಬರ ಹುಡುಕಿ • ಅಂಗಡಿ ಬೆಲೆ ಹೋಲಿಸಿ • ಸ್ಟಾಕ್ ಪರಿಶೀಲಿಸಿ'),
              style: const TextStyle(color: Colors.white)),
        ]),
      ),
      const SizedBox(height: 16),

      // search
      TextField(
        onChanged: (v) => setState(() => query = v),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: t('Search Urea, DAP, NPK, brand...', 'Urea, DAP, NPK, brand ಹುಡುಕಿ...'),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 14),

      // categories
      Text(t('Categories', 'ವರ್ಗಗಳು'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SizedBox(
        height: 42,
        child: ListView(scrollDirection: Axis.horizontal, children: categories.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_catName(item)),
              selected: category == item,
              onSelected: (_) => setState(() => category = item),
            ),
          );
        }).toList()),
      ),
      const SizedBox(height: 14),

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(t('Fertilizers & offers', 'ರಸಗೊಬ್ಬರ ಮತ್ತು ಆಫರ್‌ಗಳು'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('${filtered.length} ${t('offers', 'ಆಫರ್‌ಗಳು')}',
            style: const TextStyle(color: Colors.grey)),
      ]),
      const SizedBox(height: 8),

      ...filtered.map(_offerCard),
      const SizedBox(height: 8),
      _sourceNote(),
    ]);
  }

  String _catName(String c) {
    if (!kannada) return c;
    const m = {
      'All': 'ಎಲ್ಲಾ', 'Nitrogen': 'ನೈಟ್ರೋಜನ್', 'Phosphatic': 'ಫಾಸ್ಫೇಟಿಕ್',
      'Potassic': 'ಪೊಟ್ಯಾಶಿಕ್', 'Complex': 'ಕಾಂಪ್ಲೆಕ್ಸ್',
      'Water Soluble': 'ನೀರಿನಲ್ಲಿ ಕರಗುವ', 'Micronutrients': 'ಸೂಕ್ಷ್ಮ ಪೋಷಕಾಂಶ',
      'Organic': 'ಸಾವಯವ', 'Biofertilizer': 'ಜೈವಿಕ ಗೊಬ್ಬರ',
    };
    return m[c] ?? c;
  }

  // ─────────────────────────── Offer card ──────────────────────────────────
  Widget _offerCard(FertilizerOffer offer) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE7F3E8),
            child: Icon(Icons.grass, color: Color(0xFF237A3B)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(offer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${offer.brand} • ${offer.weight}', style: const TextStyle(color: Colors.black54)),
            Text('${offer.shopLabel}, ${offer.districtLabel}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(
              offer.stock > 0
                  ? '${t('In stock', 'ಸ್ಟಾಕ್ ಇದೆ')}: ${offer.stock}'
                  : t('Out of stock', 'ಸ್ಟಾಕ್ ಇಲ್ಲ'),
              style: TextStyle(fontSize: 12, color: offer.stock > 0 ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 8),
            Text('₹${offer.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF237A3B))),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            FilledButton(
              onPressed: offer.stock > 0
                  ? () {
                      setState(() => cart.add(offer));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(t('${offer.name} added to cart', '${offer.name} ಕಾರ್ಟ್‌ಗೆ ಸೇರಿಸಲಾಗಿದೆ')),
                      ));
                    }
                  : null,
              child: Text(t('Add to Cart', 'ಕಾರ್ಟ್‌ಗೆ ಸೇರಿಸಿ')),
            ),
            const SizedBox(height: 5),
            OutlinedButton(
              onPressed: offer.stock > 0 ? () => _buyNow(offer) : null,
              child: Text(t('Buy Now', 'ಈಗ ಖರೀದಿಸಿ')),
            ),
          ]),
        ]),
      ),
    );
  }

  // ─────────────────────────── Buy Now ─────────────────────────────────────
  Future<void> _buyNow(FertilizerOffer offer) async {
    int quantity = 1;
    final namCtrl  = TextEditingController();
    final mobCtrl  = TextEditingController();
    final addrCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (_, setS) {
        final total = offer.price * quantity;
        return AlertDialog(
          title: Text(t('Buy Now', 'ಈಗ ಖರೀದಿಸಿ')),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(offer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${offer.brand} • ${offer.weight}'),
            const SizedBox(height: 8),
            Text('₹${offer.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF237A3B))),
            const SizedBox(height: 14),
            Row(children: [
              Text(t('Quantity', 'ಪ್ರಮಾಣ')), const Spacer(),
              IconButton(onPressed: quantity > 1 ? () => setS(() => quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline)),
              Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: quantity < offer.stock ? () => setS(() => quantity++) : null,
                  icon: const Icon(Icons.add_circle_outline)),
            ]),
            const SizedBox(height: 10),
            TextField(controller: namCtrl,
                decoration: InputDecoration(labelText: t('Customer Name', 'ಗ್ರಾಹಕರ ಹೆಸರು'), border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: mobCtrl, keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t('Mobile Number', 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ'), border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: addrCtrl, maxLines: 3,
                decoration: InputDecoration(labelText: t('Delivery Address', 'ವಿತರಣಾ ವಿಳಾಸ'), border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            Text('${t('Total', 'ಒಟ್ಟು')}: ₹${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('Cancel', 'ರದ್ದು'))),
            FilledButton(
              onPressed: () {
                if (namCtrl.text.trim().isEmpty || mobCtrl.text.trim().isEmpty || addrCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t('Please fill all details', 'ದಯವಿಟ್ಟು ಎಲ್ಲಾ ವಿವರಗಳನ್ನು ತುಂಬಿ')),
                  ));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(t('Place Order', 'ಆರ್ಡರ್ ಮಾಡಿ')),
            ),
          ],
        );
      }),
    );

    if (confirmed == true && mounted) {
      final total = offer.price * quantity;
      setState(() => loading = true);

      final savedOrder = await ApiService.placeOrder(
        fertilizerId:    offer.id,
        fertilizerName:  offer.name,
        brand:           offer.brand,
        quantity:        quantity,
        totalPrice:      total,
        customerName:    namCtrl.text.trim(),
        customerMobile:  mobCtrl.text.trim(),
        customerAddress: addrCtrl.text.trim(),
      );

      if (mounted) setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(savedOrder != null
              ? '${t('Order placed!', 'ಆರ್ಡರ್ ಮಾಡಲಾಗಿದೆ!')} ${offer.name} × $quantity | ₹${total.toStringAsFixed(2)} | ID: ${savedOrder['id']}'
              : '${t('Order saved locally.', 'ಆರ್ಡರ್ ಸ್ಥಳೀಯವಾಗಿ ಉಳಿಸಲಾಗಿದೆ.')} ${offer.name} × $quantity'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ));
      }
    }

    namCtrl.dispose(); mobCtrl.dispose(); addrCtrl.dispose();
  }

  Widget _sourceNote() => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(sourceMessage, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      );

  // ─────────────────────────── Compare tab ──────────────────────────────────
  Widget _compare() {
    if (offers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                t('No products available to compare.', 'ಹೋಲಿಸಲು ಯಾವುದೇ ಉತ್ಪನ್ನಗಳು ಲಭ್ಯವಿಲ್ಲ.'),
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    final int idx1 = (compareIndex1 >= 0 && compareIndex1 < offers.length) ? compareIndex1 : 0;
    final int idx2 = (compareIndex2 >= 0 && compareIndex2 < offers.length)
        ? compareIndex2
        : (offers.length > 1 ? 1 : 0);

    final item1 = offers[idx1];
    final item2 = offers[idx2];
    final double diff = (item1.price - item2.price).abs();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          t('Compare Fertilizers', 'ರಸಗೊಬ್ಬರ ಹೋಲಿಕೆ'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF173D25)),
        ),
        const SizedBox(height: 4),
        Text(
          t('Select any two products to compare prices, brands, and shops', 'ಬೆಲೆ, ಬ್ರಾಂಡ್‌ಗಳು ಮತ್ತು ಅಂಗಡಿಗಳನ್ನು ಹೋಲಿಸಲು ಯಾವುದೇ ಎರಡು ಉತ್ಪನ್ನಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ'),
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // Dropdown Selectors
        Row(
          children: [
            Expanded(
              child: Card(
                color: const Color(0xFFF0F6F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF81C784)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: idx1,
                      hint: Text(t('Select Item 1', 'ಉತ್ಪನ್ನ 1 ಆಯ್ಕೆಮಾಡಿ')),
                      items: List.generate(offers.length, (i) {
                        final f = offers[i];
                        return DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                            '${f.name} (${f.brand})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => compareIndex1 = val);
                      },
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.compare_arrows, color: Color(0xFF237A3B), size: 28),
            ),
            Expanded(
              child: Card(
                color: const Color(0xFFF0F6F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF81C784)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: idx2,
                      hint: Text(t('Select Item 2', 'ಉತ್ಪನ್ನ 2 ಆಯ್ಕೆಮಾಡಿ')),
                      items: List.generate(offers.length, (i) {
                        final f = offers[i];
                        return DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                            '${f.name} (${f.brand})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => compareIndex2 = val);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Price Difference Banner
        if (diff > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item1.price < item2.price
                        ? '${item1.name} (${item1.brand}) is ₹${diff.toStringAsFixed(2)} cheaper!'
                        : '${item2.name} (${item2.brand}) is ₹${diff.toStringAsFixed(2)} cheaper!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Comparison Table Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _compareRow(
                  t('Product', 'ಉತ್ಪನ್ನ'),
                  item1.name,
                  item2.name,
                  isTitle: true,
                ),
                const Divider(),
                _compareRow(
                  t('Price', 'ಬೆಲೆ'),
                  '₹${item1.price.toStringAsFixed(2)}',
                  '₹${item2.price.toStringAsFixed(2)}',
                  highlightColor1: item1.price <= item2.price ? Colors.green.shade800 : null,
                  highlightColor2: item2.price <= item1.price ? Colors.green.shade800 : null,
                  isPrice: true,
                ),
                const Divider(),
                _compareRow(t('Brand', 'ಬ್ರಾಂಡ್'), item1.brand, item2.brand),
                const Divider(),
                _compareRow(t('Category', 'ವರ್ಗ'), item1.category, item2.category),
                const Divider(),
                _compareRow(t('Weight', 'ತೂಕ'), item1.weight, item2.weight),
                const Divider(),
                _compareRow(t('Shop', 'ಅಂಗಡಿ'), item1.shopLabel, item2.shopLabel),
                const Divider(),
                _compareRow(t('District', 'ಜಿಲ್ಲೆ'), item1.districtLabel, item2.districtLabel),
                const Divider(),
                _compareRow(
                  t('Stock', 'ಸ್ಟಾಕ್'),
                  item1.stock > 0 ? '${item1.stock} in stock' : 'Out of stock',
                  item2.stock > 0 ? '${item2.stock} in stock' : 'Out of stock',
                  highlightColor1: item1.stock > 0 ? Colors.green : Colors.red,
                  highlightColor2: item2.stock > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF237A3B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: item1.stock > 0 ? () => _buyNow(item1) : null,
                        child: Text(t('Buy Item 1', 'ಉತ್ಪನ್ನ 1 ಖರೀದಿಸಿ'), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF237A3B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: item2.stock > 0 ? () => _buyNow(item2) : null,
                        child: Text(t('Buy Item 2', 'ಉತ್ಪನ್ನ 2 ಖರೀದಿಸಿ'), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text(
          t('Tap any offer below to compare', 'ಹೋಲಿಸಲು ಕೆಳಗಿನ ಯಾವುದೇ ಆಫರ್ ಮೇಲೆ ಕ್ಲಿಕ್ ಮಾಡಿ'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        ...offers.asMap().entries.map((entry) {
          final i = entry.key;
          final offer = entry.value;
          final isSelected1 = idx1 == i;
          final isSelected2 = idx2 == i;
          return Card(
            color: (isSelected1 || isSelected2) ? const Color(0xFFE8F5E9) : Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${offer.name} — ${offer.brand}', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${offer.weight} • ₹${offer.price} • ${offer.shopLabel}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: isSelected1 ? const Color(0xFF237A3B) : Colors.grey.shade400),
                    ),
                    onPressed: () => setState(() => compareIndex1 = i),
                    child: Text('Slot 1', style: TextStyle(color: isSelected1 ? const Color(0xFF237A3B) : Colors.black87, fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: isSelected2 ? const Color(0xFF237A3B) : Colors.grey.shade400),
                    ),
                    onPressed: () => setState(() => compareIndex2 = i),
                    child: Text('Slot 2', style: TextStyle(color: isSelected2 ? const Color(0xFF237A3B) : Colors.black87, fontSize: 11)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _compareRow(
    String label,
    String val1,
    String val2, {
    bool isTitle = false,
    bool isPrice = false,
    Color? highlightColor1,
    Color? highlightColor2,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              val1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isTitle || isPrice ? FontWeight.bold : FontWeight.w500,
                fontSize: isPrice ? 16 : (isTitle ? 15 : 13),
                color: highlightColor1 ?? (isPrice ? const Color(0xFF237A3B) : Colors.black87),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8F3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              val2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isTitle || isPrice ? FontWeight.bold : FontWeight.w500,
                fontSize: isPrice ? 16 : (isTitle ? 15 : 13),
                color: highlightColor2 ?? (isPrice ? const Color(0xFF237A3B) : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Shops tab ────────────────────────────────────
  Widget _shops() {
    final shopNames = offers.map((e) => e.shopLabel).where((s) => s.isNotEmpty).toSet().toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(t('Available Shops & Distributors', 'ಲಭ್ಯವಿರುವ ಅಂಗಡಿಗಳು ಮತ್ತು ವಿತರಕರು'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      ...shopNames.map((shop) => Card(
            child: ListTile(
              leading: const Icon(Icons.storefront, color: Color(0xFF237A3B)),
              title: Text(shop),
              subtitle: Text(
                '${offers.where((e) => e.shopLabel == shop).length} ${t('fertilizers available', 'ರಸಗೊಬ್ಬರ ಲಭ್ಯವಿದೆ')}',
              ),
            ),
          )),
    ]);
  }

  // ─────────────────────────── Cart tab ─────────────────────────────────────
  Widget _cart() {
    final total = cart.fold<double>(0, (s, i) => s + i.price);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(t('My Cart', 'ನನ್ನ ಕಾರ್ಟ್'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      if (cart.isEmpty)
        Center(child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(t('Your cart is empty', 'ನಿಮ್ಮ ಕಾರ್ಟ್ ಖಾಲಿಯಾಗಿದೆ')),
        ))
      else ...[
        ...cart.map((item) => Card(
              color: Colors.white,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE7F3E8),
                  child: Icon(Icons.grass, color: Color(0xFF237A3B)),
                ),
                title: Text(item.name),
                subtitle: Text('${item.brand} • ${item.weight}\n${item.shopLabel}'),
                isThreeLine: true,
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('₹${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => _buyNow(item),
                    child: Text(t('Buy Now', 'ಈಗ ಖರೀದಿಸಿ')),
                  ),
                ]),
              ),
            )),
        const SizedBox(height: 10),
        Text('${t('Total', 'ಒಟ್ಟು')}: ₹${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: cart.isEmpty ? null : () => _buyNow(cart.first),
          icon: const Icon(Icons.shopping_bag),
          label: Text(t('Buy Now', 'ಈಗ ಖರೀದಿಸಿ')),
        ),
      ],
    ]);
  }

  // ─────────────────────────── Profile tab ──────────────────────────────────
  Widget _profile() {
    final user = NeonAuthService.currentUser;
    return _ProfileTab(user: user, t: t);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile tab widget (stateful — fetches order history)
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatefulWidget {
  final UserProfile? user;
  final String Function(String, String) t;

  const _ProfileTab({required this.user, required this.t});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  List<dynamic> _orders    = [];
  bool          _loading   = true;
  String?       _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    final data = await ApiService.fetchProfile();
    if (!mounted) return;
    if (data != null && data['success'] == true) {
      setState(() {
        _orders  = data['orders'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } else {
      setState(() { _loading = false; _error = 'Could not load orders.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return ListView(padding: const EdgeInsets.all(16), children: [
      // User card
      Card(color: Colors.white, child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFFE7F3E8),
            child: Icon(Icons.person, size: 36, color: Color(0xFF237A3B)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u?.displayName.isNotEmpty == true ? u!.displayName : widget.t('No name set', 'ಹೆಸರಿಲ್ಲ'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(u?.email ?? '', style: const TextStyle(color: Colors.black54)),
          ])),
        ]),
      )),

      const SizedBox(height: 20),

      Text(widget.t('My Orders', 'ನನ್ನ ಆರ್ಡರ್‌ಗಳು'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),

      if (_loading)
        const Center(child: CircularProgressIndicator())
      else if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.red))
      else if (_orders.isEmpty)
        Text(widget.t('No orders yet.', 'ಇನ್ನೂ ಆರ್ಡರ್ ಇಲ್ಲ.'),
            style: const TextStyle(color: Colors.grey))
      else
        ..._orders.map((o) {
          final order = o as Map<String, dynamic>;
          final isCancelled = (order['status'] as String? ?? '').toLowerCase() == 'cancelled';
          final statusStr = (order['status'] as String? ?? 'placed').toUpperCase();
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCancelled ? Colors.red.shade50 : const Color(0xFFE7F3E8),
                  child: Icon(
                    isCancelled ? Icons.cancel_outlined : Icons.receipt_long,
                    color: isCancelled ? Colors.red : const Color(0xFF237A3B),
                  ),
                ),
                title: Text(
                  '${order['fertilizer_name']} × ${order['quantity']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      '₹${order['total_price']}  •  $statusStr',
                      style: TextStyle(
                        color: isCancelled ? Colors.red : const Color(0xFF237A3B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      (order['created_at'] as String?)?.substring(0, 10) ?? '',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCancelled)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(widget.t('Cancel Order', 'ಆರ್ಡರ್ ರದ್ದುಮಾಡಿ')),
                              content: Text(widget.t(
                                'Are you sure you want to cancel this order?',
                                'ನೀವು ಖಚಿತವಾಗಿ ಈ ಆರ್ಡರ್ ರದ್ದುಗೊಳಿಸಲು ಬಯಸುವಿರಾ?',
                              )),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(widget.t('No', 'ಇಲ್ಲ')),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(widget.t('Cancel Order', 'ಆರ್ಡರ್ ರದ್ದುಮಾಡಿ')),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final ok = await ApiService.cancelOrder(order['id'] as int);
                            if (context.mounted) {
                              if (ok) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(widget.t('Order cancelled successfully', 'ಆರ್ಡರ್ ಯಶಸ್ವಿಯಾಗಿ ರದ್ದುಗೊಂಡಿದೆ')),
                                ));
                                _loadProfile();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(widget.t('Failed to cancel order', 'ಆರ್ಡರ್ ರದ್ದುಗೊಳಿಸಲು ವಿಫಲವಾಗಿದೆ')),
                                ));
                              }
                            }
                          }
                        },
                        child: Text(widget.t('Cancel', 'ರದ್ದು')),
                      ),
                    Text('#${order['id']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        }),

      const SizedBox(height: 32),

      // ── Logout Button on Profile Page ──────────────────────────────────────
      Center(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(widget.t('Sign Out', 'ಸೈನ್ ಔಟ್')),
                content: Text(widget.t(
                  'Are you sure you want to sign out?',
                  'ನೀವು ಖಚಿತವಾಗಿ ಸೈನ್ ಔಟ್ ಮಾಡಲು ಬಯಸುವಿರಾ?',
                )),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(widget.t('Cancel', 'ರದ್ದು')),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(widget.t('Sign Out', 'ಸೈನ್ ಔಟ್')),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await NeonAuthService.signOut();
            }
          },
          icon: const Icon(Icons.logout, size: 18),
          label: Text(
            widget.t('Sign Out', 'ಸೈನ್ ಔಟ್'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ]);
  }
}
