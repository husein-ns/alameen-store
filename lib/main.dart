import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://idaxgihzqbgzvellxlxn.supabase.co',
    anonKey: 'sb_publishable_5upJjPyzgNRV9Rk-1WeWjg_RffVxRMn',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

// إيميلك المعتمد كمدير رسمي
const String kAdminEmail = 'gametrailerengilish@gmail.com';

// رقم الواتساب الخاص بك للطلبات
const String kWhatsAppNumber = '9647700000000';

// سعر التوصيل الثابت لجميع المحافظات
const double kDeliveryFee = 5000.0;

// سلة التسوق العامة
final ValueNotifier<List<Map<String, dynamic>>> cartNotifier = ValueNotifier(
  [],
);

// مفتاح رئيسي للتحكم بالقائمة السفلية
final GlobalKey<MainNavigationScreenState> navKey =
    GlobalKey<MainNavigationScreenState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'متجر الأمين',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 1,
        ),
      ),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: supabase.auth.currentSession != null
          ? MainNavigationScreen(key: navKey, isGuest: false)
          : const AuthLandingScreen(),
    );
  }
}

// ==========================================
// شاشة البداية
// ==========================================
class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة البريد الإلكتروني وكلمة المرور'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await supabase.auth.signUp(email: email, password: password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم إنشاء الحساب بنجاح!')),
          );
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(key: navKey, isGuest: false),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _enterAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(key: navKey, isGuest: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'إنشاء حساب جديد' : 'تسجيل الدخول'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSignUp ? Icons.person_add : Icons.account_circle,
                      size: 60,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isSignUp
                          ? 'إنشاء حساب في متجر الأمين'
                          : 'تسجيل الدخول لحسابك',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: _isLoading ? null : _submitAuth,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _isSignUp
                                    ? 'إنشاء الحساب الآن'
                                    : 'تسجيل الدخول',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                            : 'ليس لديك حساب؟ اضغط هنا لإنشاء حساب جديد',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 24),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      icon: const Icon(Icons.storefront),
                      label: const Text(
                        'الدخول كضيف للمتجر',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _enterAsGuest,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// شريط التنقل الرئيسي
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  final bool isGuest;
  final int initialIndex;
  const MainNavigationScreen({
    super.key,
    required this.isGuest,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final bool isAdmin =
        !widget.isGuest && user != null && user.email == kAdminEmail;

    final List<Widget> screens = [
      HomeScreen(isAdmin: isAdmin, isGuest: widget.isGuest),
      CategoriesScreen(isGuest: widget.isGuest),
      const CartScreen(),
      isAdmin
          ? const AdminOrdersScreen()
          : OrdersHistoryScreen(isGuest: widget.isGuest),
      AccountTabScreen(isGuest: widget.isGuest, isAdmin: isAdmin),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey.shade600,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'الرئيسية',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'الأقسام',
          ),
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: cartNotifier,
              builder: (_, cart, __) => Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text('${cart.length}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            label: 'السلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(isAdmin ? Icons.inventory_2 : Icons.receipt_long),
            label: isAdmin ? 'الطلبات' : 'طلباتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
            ),
            label: isAdmin ? 'لوحة الإدارة' : 'حسابي',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 1. الرئيسية
// ==========================================
class HomeScreen extends StatefulWidget {
  final bool isAdmin;
  final bool isGuest;
  const HomeScreen({super.key, required this.isAdmin, required this.isGuest});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = supabase
          .from('products')
          .select()
          .order('id', ascending: false)
          .then((data) => List<Map<String, dynamic>>.from(data));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'متجر الأمين',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: cartNotifier,
            builder: (context, cart, _) => IconButton(
              icon: Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text('${cart.length}'),
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: () {
                navKey.currentState?.switchTab(2);
              },
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'إضافة منتج جديد',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
                if (res == true) _loadProducts();
              },
            )
          : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في الاتصال: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('لا توجد منتجات منشورة حالياً'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              int cols = constraints.maxWidth > 1100
                  ? 4
                  : (constraints.maxWidth > 750 ? 3 : 2);

              return GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: constraints.maxWidth > 750 ? 0.75 : 0.64,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final item = products[index];
                  final String mainImg = (item['image_url'] ?? '')
                      .toString()
                      .trim();
                  final String title = item['name'] ?? item['title'] ?? 'منتج';
                  final dynamic price = item['price'] ?? 0;
                  final colors =
                      item['colors'] != null && item['colors'] is List
                      ? item['colors']
                      : [];
                  final String defaultColor = colors.isNotEmpty
                      ? colors.first.toString()
                      : 'قياسي';

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailsScreen(
                                    product: item,
                                    isGuest: widget.isGuest,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              color: Colors.grey.shade100,
                              child: mainImg.isNotEmpty
                                  ? Image.network(
                                      mainImg,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 40,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailsScreen(
                                        product: item,
                                        isGuest: widget.isGuest,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$price د.ع',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailsScreen(
                                                  product: item,
                                                  isGuest: widget.isGuest,
                                                ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'اطلب الآن',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: IconButton(
                                      constraints: const BoxConstraints(
                                        minWidth: 34,
                                        minHeight: 34,
                                      ),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.add_shopping_cart,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'إضافة للسلة',
                                      onPressed: () {
                                        cartNotifier.value = [
                                          ...cartNotifier.value,
                                          {
                                            'name': title,
                                            'price': price,
                                            'image': mainImg,
                                            'color': defaultColor,
                                          },
                                        ];
                                        ScaffoldMessenger.of(context)
                                            .hideCurrentSnackBar();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '✅ تمت إضافة ($title) للسلة',
                                            ),
                                            duration: const Duration(
                                              seconds: 1,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.only(
                                              bottom: 70,
                                              left: 20,
                                              right: 20,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 2. تفاصيل المنتج + طلب مباشر
// ==========================================
class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isGuest;
  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.isGuest,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final PageController _pageController = PageController();
  int _currImg = 0;
  String? _selectedColor;

  List<String> _getImages() {
    List<String> imgs = [];
    if (widget.product['image_url'] != null &&
        widget.product['image_url'].toString().trim().isNotEmpty) {
      imgs.add(widget.product['image_url'].toString().trim());
    }
    if (widget.product['images'] != null && widget.product['images'] is List) {
      for (var img in widget.product['images']) {
        String url = img.toString().trim();
        if (url.isNotEmpty && !imgs.contains(url)) {
          imgs.add(url);
        }
      }
    }
    return imgs;
  }

  String? _extractYouTubeId(String url) {
    if (url.isEmpty) return null;
    try {
      final uri = Uri.parse(url.trim());
      if (uri.pathSegments.contains('shorts') && uri.pathSegments.length > 1) {
        return uri.pathSegments[1];
      }
      if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
    } catch (_) {}
    return null;
  }

  Color _getColorFromName(String name) {
    switch (name) {
      case 'أسود':
        return Colors.black;
      case 'فضي':
        return Colors.grey.shade400;
      case 'أحمر':
        return Colors.red.shade600;
      case 'أصفر':
        return Colors.amber.shade500;
      case 'أبيض':
        return Colors.white;
      case 'أزرق':
        return Colors.blue.shade600;
      default:
        return Colors.blueGrey;
    }
  }

  void _openWhatsApp(String title, dynamic price) {
    final String chosenCol = _selectedColor ?? 'افتراضي';
    final String msg = Uri.encodeComponent(
      'السلام عليكم متجر الأمين،\nأود طلب المنتج التالي:\n- المنتج: $title\n- اللون: $chosenCol\n- السعر: $price د.ع (+ 5,000 د.ع توصيل لجميع المحافظات)\nيرجى تثبيت الطلب.',
    );
    final String url = 'https://wa.me/$kWhatsAppNumber?text=$msg';
    web.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final bool isAdmin =
        !widget.isGuest && user != null && user.email == kAdminEmail;

    final imgs = _getImages();
    final title = widget.product['name'] ?? widget.product['title'] ?? '';
    final price = widget.product['price'] ?? 0;
    final desc = widget.product['description'] ?? '';
    final String videoRaw = widget.product['video_url'] ?? '';
    final String? youtubeVideoId = _extractYouTubeId(videoRaw);
    final colors =
        widget.product['colors'] != null && widget.product['colors'] is List
        ? List<dynamic>.from(widget.product['colors'])
        : [];

    if (_selectedColor == null && colors.isNotEmpty) {
      _selectedColor = colors.first.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: cartNotifier,
            builder: (context, cart, _) => IconButton(
              icon: Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text('${cart.length}'),
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: () {
                Navigator.pop(context);
                navKey.currentState?.switchTab(2);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          Navigator.pop(context);
          navKey.currentState?.switchTab(i);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey.shade600,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'الرئيسية',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'الأقسام',
          ),
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: cartNotifier,
              builder: (_, cart, __) => Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text('${cart.length}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            label: 'السلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(isAdmin ? Icons.inventory_2 : Icons.receipt_long),
            label: isAdmin ? 'الطلبات' : 'طلباتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
            ),
            label: isAdmin ? 'لوحة الإدارة' : 'حسابي',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          Widget imageSection = Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: isWide ? 420 : 320,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: imgs.length,
                      onPageChanged: (i) => setState(() => _currImg = i),
                      itemBuilder: (_, i) => Image.network(
                        imgs[i],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (imgs.length > 1) ...[
                    Positioned(
                      right: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withAlpha(120),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () {
                            if (_currImg > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withAlpha(120),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () {
                            if (_currImg < imgs.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (imgs.length > 1)
                SizedBox(
                  height: 65,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imgs.length,
                    itemBuilder: (_, i) {
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 65,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _currImg == i
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(imgs[i], fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );

          Widget detailsSection = Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '$price د.ع',
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '🚚 توصيل 5,000 د.ع لكل المحافظات',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (colors.isNotEmpty) ...[
                    const Text(
                      'اختر اللون المتوفر:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      children: colors.map((c) {
                        final String colName = c.toString();
                        final isSel = _selectedColor == colName;
                        final col = _getColorFromName(colName);

                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = colName),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.blue.shade50 : Colors.white,
                              border: Border.all(
                                color: isSel
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 8,
                                  backgroundColor: col,
                                  child: isSel
                                      ? const Icon(
                                          Icons.check,
                                          size: 10,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  colName,
                                  style: TextStyle(
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade800,
                              side: BorderSide(
                                color: Colors.blue.shade800,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text(
                              'إضافة للسلة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () {
                              cartNotifier.value = [
                                ...cartNotifier.value,
                                {
                                  'name': title,
                                  'price': price,
                                  'image': imgs.isNotEmpty ? imgs.first : '',
                                  'color':
                                      _selectedColor ??
                                      (colors.isNotEmpty
                                          ? colors.first.toString()
                                          : 'قياسي'),
                                },
                              ];
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ تمت إضافة ($title) للسلة'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.only(
                                    bottom: 70,
                                    left: 20,
                                    right: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.flash_on,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'اطلب الآن',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            onPressed: () =>
                                _showDirectOrderDialog(context, title, price),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text(
                        'أو اطلب عبر الواتساب مباشرة',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () => _openWhatsApp(title, price),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'الوصف والمواصفات:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: imageSection),
                      const SizedBox(width: 20),
                      Expanded(flex: 6, child: detailsSection),
                    ],
                  )
                else ...[
                  imageSection,
                  const SizedBox(height: 14),
                  detailsSection,
                ],
                if (youtubeVideoId != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    '🎬 فيديو تجربة واستخدام المنتج:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: isWide ? 400 : 260,
                    width: isWide ? 680 : double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: WebVideoPlayer(videoId: youtubeVideoId),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDirectOrderDialog(
    BuildContext context,
    String title,
    dynamic productPrice,
  ) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    String prov = 'بغداد';
    bool isSubmitting = false;
    final double itemPrice = double.tryParse(productPrice.toString()) ?? 0;
    final double totalWithDelivery = itemPrice + kDeliveryFee;

    final List<String> provinces = [
      'بغداد',
      'البصرة',
      'نينوى (الموصل)',
      'أربيل',
      'النجف الأشرف',
      'كربلاء المقدسة',
      'بابل (الحلة)',
      'ديالى',
      'الأنبار',
      'كركوك',
      'صلاح الدين',
      'واسط (الكوت)',
      'ميسان (العمارة)',
      'ذي قار (الناصرية)',
      'المثنى (السماوة)',
      'القادسية (الديوانية)',
      'السليمانية',
      'دهوك',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلب مباشر: $title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اللون: ${_selectedColor ?? "قياسي"}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('سعر المنتج:'),
                          Text(
                            '$itemPrice د.ع',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('كلفة التوصيل (ثابت لكل العراق):'),
                          Text(
                            '5,000 د.ع',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'المبلغ الكلي عند الاستلام:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '$totalWithDelivery د.ع',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف العراقي (11 رقم يبدأ بـ 07) *',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: prov,
                  items: provinces
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setModalState(() => prov = v!),
                  decoration: const InputDecoration(
                    labelText: 'المحافظة *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان التفصيلي / أقرب نقطة دالة *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final cName = nameCtrl.text.trim();
                            final cPhone = phoneCtrl.text.trim();
                            final cAddr = addrCtrl.text.trim();

                            if (cName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('يرجى كتابة الاسم الكامل'),
                                ),
                              );
                              return;
                            }

                            if (cPhone.length != 11 ||
                                !cPhone.startsWith('07') ||
                                int.tryParse(cPhone) == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'يجب إدخال رقم هاتف عراقي صحيح مكون من 11 رقماً ويبدأ بـ 07',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (cAddr.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'العنوان التفصيلي إلزامي لضمان وصول الطلب',
                                  ),
                                ),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);

                            try {
                              await supabase.from('orders').insert({
                                'product_name': title,
                                'price': totalWithDelivery,
                                'total_amount': totalWithDelivery,
                                'customer_name': cName,
                                'phone': cPhone,
                                'province': prov,
                                'address': cAddr,
                                'selected_color': _selectedColor ?? 'قياسي',
                                'status': 'قيد التجهيز',
                              });

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 تم تأكيد الطلب بنجاح!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تعذر إرسال الطلب: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'تأكيد الطلب الآن',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. شاشة السلة
// ==========================================
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سلة التسوق')),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: cartNotifier,
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'سلة التسوق فارغة حالياً',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      navKey.currentState?.switchTab(0);
                    },
                    child: const Text('تصفح المنتجات الآن'),
                  ),
                ],
              ),
            );
          }

          double subtotal = cart.fold(
            0.0,
            (sum, item) =>
                sum + (double.tryParse(item['price'].toString()) ?? 0),
          );
          double grandTotal = subtotal + kDeliveryFee;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final item = cart[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade100,
                          ),
                          child: item['image'].toString().isNotEmpty
                              ? Image.network(item['image'], fit: BoxFit.cover)
                              : const Icon(Icons.image),
                        ),
                        title: Text(
                          item['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('اللون: ${item['color']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item['price']} د.ع',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                final updated = List<Map<String, dynamic>>.from(
                                  cart,
                                );
                                updated.removeAt(i);
                                cartNotifier.value = updated;
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'مجموع المنتجات:',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '$subtotal د.ع',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'أجور التوصيل (ثابت لكل العراق):',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '5,000 د.ع',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الإجمالي الكلي:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '$grandTotal د.ع',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () =>
                              _showCheckoutDialog(context, grandTotal, cart),
                          child: const Text(
                            'إتمام طلب السلة',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCheckoutDialog(
    BuildContext context,
    double total,
    List<Map<String, dynamic>> items,
  ) {
    final name = TextEditingController();
    final phone = TextEditingController();
    final addr = TextEditingController();
    String prov = 'بغداد';
    bool isSubmitting = false;

    final List<String> provinces = [
      'بغداد',
      'البصرة',
      'نينوى (الموصل)',
      'أربيل',
      'النجف الأشرف',
      'كربلاء المقدسة',
      'بابل (الحلة)',
      'ديالى',
      'الأنبار',
      'كركوك',
      'صلاح الدين',
      'واسط (الكوت)',
      'ميسان (العمارة)',
      'ذي قار (الناصرية)',
      'المثنى (السماوة)',
      'القادسية (الديوانية)',
      'السليمانية',
      'دهوك',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('تأكيد بيانات التوصيل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'المبلغ الكلي شامل التوصيل: $total د.ع',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف العراقي (11 رقم يبدأ بـ 07) *',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: prov,
                items: provinces
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setDlgState(() => prov = v!),
                decoration: const InputDecoration(
                  labelText: 'المحافظة *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addr,
                decoration: const InputDecoration(
                  labelText: 'العنوان التفصيلي / نقطة دالة *',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final customerName = name.text.trim();
                      final customerPhone = phone.text.trim();
                      final customerAddr = addr.text.trim();

                      if (customerName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يرجى كتابة الاسم الكامل'),
                          ),
                        );
                        return;
                      }

                      if (customerPhone.length != 11 ||
                          !customerPhone.startsWith('07') ||
                          int.tryParse(customerPhone) == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'يجب إدخال رقم هاتف عراقي صحيح مكون من 11 رقماً ويبدأ بـ 07',
                            ),
                          ),
                        );
                        return;
                      }

                      if (customerAddr.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'العنوان التفصيلي إلزامي لضمان وصول الطلب',
                            ),
                          ),
                        );
                        return;
                      }

                      setDlgState(() => isSubmitting = true);

                      try {
                        for (var itm in items) {
                          final itemPrice =
                              double.tryParse(itm['price'].toString()) ?? 0.0;
                          await supabase.from('orders').insert({
                            'product_name': itm['name'] ?? 'منتج',
                            'price': itemPrice,
                            'total_amount': itemPrice,
                            'customer_name': customerName,
                            'phone': customerPhone,
                            'province': prov,
                            'address': customerAddr,
                            'selected_color': itm['color'] ?? 'قياسي',
                            'status': 'قيد التجهيز',
                          });
                        }

                        cartNotifier.value = [];

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          navKey.currentState?.switchTab(0);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '🎉 تم إرسال الطلب بنجاح وتفريغ السلة!',
                              ),
                              duration: Duration(seconds: 3),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ أثناء إرسال الطلب: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'إرسال الطلب',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. الأقسام (تفتح المنتجات الخاصة بالقسم فعلياً)
// ==========================================
class CategoriesScreen extends StatelessWidget {
  final bool isGuest;
  const CategoriesScreen({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'name': 'عروض وتخفيضات', 'icon': Icons.local_offer, 'color': Colors.red},
      {'name': 'إلكترونيات', 'icon': Icons.devices, 'color': Colors.indigo},
      {
        'name': 'أدوات السيارات',
        'icon': Icons.directions_car,
        'color': Colors.blue,
      },
      {'name': 'أجهزة المنزل', 'icon': Icons.home, 'color': Colors.teal},
      {
        'name': 'أجهزة المطبخ',
        'icon': Icons.kitchen,
        'color': Colors.deepOrange,
      },
      {
        'name': 'أدوات مطبخ',
        'icon': Icons.restaurant,
        'color': Colors.amber.shade800,
      },
      {'name': 'أجهزة العناية', 'icon': Icons.face, 'color': Colors.purple},
      {'name': 'منتجات العناية', 'icon': Icons.spa, 'color': Colors.pink},
      {
        'name': 'ألعاب أطفال',
        'icon': Icons.sports_esports,
        'color': Colors.orange,
      },
      {'name': 'عدد وأدوات', 'icon': Icons.build, 'color': Colors.blueGrey},
      {'name': 'أدوات منزلية', 'icon': Icons.cottage, 'color': Colors.brown},
      {'name': 'إنارة وإضاءة', 'icon': Icons.lightbulb, 'color': Colors.amber},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('أقسام المتجر')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 1.1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final Color col = cat['color'] as Color;
              final String catName = cat['name'] as String;

              return InkWell(
                onTap: () {
                  // فتح شاشة المنتجات التابعة للقسم المختار مباشرة
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryProductsScreen(
                        categoryName: catName,
                        isGuest: isGuest,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: col.withAlpha(25),
                        child: Icon(
                          cat['icon'] as IconData,
                          size: 28,
                          color: col,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        catName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// شاشة عرض منتجات القسم المختار
class CategoryProductsScreen extends StatelessWidget {
  final String categoryName;
  final bool isGuest;
  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('products')
            .select()
            .order('id', ascending: false)
            .then((data) {
              final list = List<Map<String, dynamic>>.from(data);
              // فلترة المنتجات حسب القسم (أو عرض الكل إذا كان القسم عروض وتخفيضات)
              if (categoryName == 'عروض وتخفيضات') return list;
              return list.where((item) {
                final String c = (item['category'] ?? '').toString();
                final String title = (item['name'] ?? item['title'] ?? '')
                    .toString();
                final String desc = (item['description'] ?? '').toString();
                return c == categoryName ||
                    title.contains(categoryName) ||
                    desc.contains(categoryName);
              }).toList();
            }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد منتجات في قسم ($categoryName) حالياً',
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('الرجوع للأقسام'),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              int cols = constraints.maxWidth > 1100
                  ? 4
                  : (constraints.maxWidth > 750 ? 3 : 2);

              return GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: constraints.maxWidth > 750 ? 0.75 : 0.64,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final item = products[index];
                  final String mainImg = (item['image_url'] ?? '')
                      .toString()
                      .trim();
                  final String title = item['name'] ?? item['title'] ?? 'منتج';
                  final dynamic price = item['price'] ?? 0;
                  final colors =
                      item['colors'] != null && item['colors'] is List
                      ? item['colors']
                      : [];
                  final String defaultColor = colors.isNotEmpty
                      ? colors.first.toString()
                      : 'قياسي';

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailsScreen(
                                    product: item,
                                    isGuest: isGuest,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              color: Colors.grey.shade100,
                              child: mainImg.isNotEmpty
                                  ? Image.network(
                                      mainImg,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 40,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$price د.ع',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailsScreen(
                                                  product: item,
                                                  isGuest: isGuest,
                                                ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'اطلب الآن',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: IconButton(
                                      constraints: const BoxConstraints(
                                        minWidth: 34,
                                        minHeight: 34,
                                      ),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.add_shopping_cart,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        cartNotifier.value = [
                                          ...cartNotifier.value,
                                          {
                                            'name': title,
                                            'price': price,
                                            'image': mainImg,
                                            'color': defaultColor,
                                          },
                                        ];
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '✅ تمت إضافة ($title) للسلة',
                                                ),
                                                duration: const Duration(
                                                  seconds: 1,
                                                ),
                                              ),
                                            );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 5. لوحة إدارة الطلبات + إحصائيات الدروب شيبينغ للمدير
// ==========================================
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = supabase
          .from('orders')
          .select()
          .order('id', ascending: false)
          .then((d) => List<Map<String, dynamic>>.from(d));
    });
  }

  void _callCustomer(String phone) {
    web.window.open('tel:$phone', '_self');
  }

  void _whatsAppCustomer(String phone, String name, String product) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'مرحباً $name، نود تأكيد طلبك ($product) من متجر الأمين.',
    );
    web.window.open('https://wa.me/$cleanPhone?text=$msg', '_blank');
  }

  Future<void> _updateOrderStatus(
    dynamic orderId,
    String newStatus,
    Map<String, dynamic> orderItem,
  ) async {
    setState(() {
      orderItem['status'] = newStatus;
    });

    try {
      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم تغيير حالة الطلب إلى ($newStatus)'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر التحديث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _loadOrders();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'تم التوصيل':
        return Colors.green;
      case 'تم الشحن':
        return Colors.blue;
      case 'ملغي':
        return Colors.red;
      case 'قيد التجهيز':
      default:
        return Colors.orange;
    }
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = ['قيد التجهيز', 'تم الشحن', 'تم التوصيل', 'ملغي'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات والإحصائيات'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في التحميل: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          int totalOrders = orders.length;
          int pendingCount = orders
              .where((o) => (o['status'] ?? '') == 'قيد التجهيز')
              .length;
          int shippedCount = orders
              .where((o) => (o['status'] ?? '') == 'تم الشحن')
              .length;
          int deliveredCount = orders
              .where((o) => (o['status'] ?? '') == 'تم التوصيل')
              .length;

          double deliveredRevenue = orders
              .where((o) => (o['status'] ?? '') == 'تم التوصيل')
              .fold(
                0.0,
                (sum, o) =>
                    sum +
                    (double.tryParse(
                          (o['total_amount'] ?? o['price']).toString(),
                        ) ??
                        0),
              );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'لوحة المؤشرات وأداء المبيعات',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.9,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            _buildStatCard(
                              'أرباح واصلة',
                              '$deliveredRevenue د.ع',
                              Icons.payments,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'إجمالي الطلبات',
                              '$totalOrders طلب',
                              Icons.shopping_bag,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'بانتظار طلبك بالمنصة',
                              '$pendingCount طلب',
                              Icons.hourglass_top,
                              Colors.orange,
                            ),
                            _buildStatCard(
                              'مشحونة مع المنصة',
                              '$shippedCount طلب',
                              Icons.local_shipping,
                              Colors.indigo,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'قائمة الطلبات الواردة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'المكتمل: $deliveredCount',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30.0),
                      child: Center(child: Text('لا توجد طلبات واردة حالياً')),
                    )
                  else
                    ...orders.map((o) {
                      final String currentStatus =
                          o['status']?.toString() ?? 'قيد التجهيز';
                      final String phone = o['phone']?.toString() ?? '';
                      final String name = o['customer_name']?.toString() ?? '';
                      final String product =
                          o['product_name']?.toString() ?? '';
                      final dynamic orderPrice =
                          o['total_amount'] ?? o['price'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$orderPrice د.ع',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'الزبون: $name',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'الهاتف: $phone',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'المحافظة: ${o['province'] ?? ""}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'العنوان التفصيلي: ${o['address'] ?? ""}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              Text(
                                'اللون المختار: ${o['selected_color']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const Divider(height: 18),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.call,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'اتصال هاتف',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onPressed: () => _callCustomer(phone),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.chat,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'مراسلة واتساب',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onPressed: () =>
                                        _whatsAppCustomer(phone, name, product),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'تحديث مسار الطلب:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: statuses.map((st) {
                                  final bool isSelected = currentStatus == st;
                                  final Color color = _getStatusColor(st);

                                  return InkWell(
                                    onTap: () {
                                      if (!isSelected) {
                                        _updateOrderStatus(o['id'], st, o);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? color
                                            : color.withAlpha(25),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: color,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        st,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : color,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// سجل طلبات الزبون العادي
// ==========================================
class OrdersHistoryScreen extends StatelessWidget {
  final bool isGuest;
  const OrdersHistoryScreen({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('سجل طلباتي')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 70, color: Colors.grey.shade400),
                const SizedBox(height: 14),
                const Text(
                  'أنت تتصفح كضيف حالياً',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'يرجى تسجيل الدخول أو إنشاء حساب لحفظ طلباتك ومتابعتها مباشرة',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('تسجيل الدخول / إنشاء حساب'),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuthLandingScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('سجل طلباتي')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('orders')
            .select()
            .order('id', ascending: false)
            .then((d) => List<Map<String, dynamic>>.from(d)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data ?? [];
          if (orders.isEmpty)
            return const Center(child: Text('لا توجد طلبات مسجلة بحسابك'));
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: orders.length,
                itemBuilder: (_, i) {
                  final o = orders[i];
                  final dynamic orderPrice =
                      o['total_amount'] ?? o['price'] ?? 0;
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.shopping_bag,
                        color: Colors.blue,
                      ),
                      title: Text(
                        o['product_name'] ?? 'طلب',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'الحالة: ${o['status'] ?? "قيد التجهيز"}\n(اللون: ${o['selected_color']})',
                      ),
                      trailing: Text(
                        '$orderPrice د.ع',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// مشغل يوتيوب
class WebVideoPlayer extends StatefulWidget {
  final String videoId;
  const WebVideoPlayer({super.key, required this.videoId});

  @override
  State<WebVideoPlayer> createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<WebVideoPlayer> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'yt-${widget.videoId}-${DateTime.now().millisecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src =
            'https://www.youtube.com/embed/${widget.videoId}?rel=0&autoplay=0'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
        ..allowFullscreen = true;
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}

// ==========================================
// 6. شاشة إضافة منتج جديد (مع اختيار القسم)
// ==========================================
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _name = TextEditingController(
    text: 'قلم تصليح ومعالجة خدوش السيارات الفوري',
  );
  final _price = TextEditingController(text: '10000');
  final _stock = TextEditingController(text: '100');
  String _selectedCategory = 'أدوات السيارات';

  final List<String> _categoriesList = [
    'أدوات السيارات',
    'إلكترونيات',
    'أجهزة المنزل',
    'أجهزة المطبخ',
    'أدوات مطبخ',
    'أجهزة العناية',
    'منتجات العناية',
    'ألعاب أطفال',
    'عدد وأدوات',
    'أدوات منزلية',
    'إنارة وإضاءة',
    'عروض وتخفيضات',
  ];

  final _mainImg = TextEditingController(
    text: 'https://idaxgihzqbgzvellxlxn.supabase.co/storage/v1/object/public/products/photo_1_2026-09-01_18-18-02.jpg',
  );
  final _albumImgs = TextEditingController(
    text: 'https://idaxgihzqbgzvellxlxn.supabase.co/storage/v1/object/public/products/photo_2_2026-09-01_18-18-02.jpg, https://idaxgihzqbgzvellxlxn.supabase.co/storage/v1/object/public/products/photo_3_2026-09-01_18-18-02.jpg, https://idaxgihzqbgzvellxlxn.supabase.co/storage/v1/object/public/products/photo_4_2026-09-01_18-18-02.jpg, https://idaxgihzqbgzvellxlxn.supabase.co/storage/v1/object/public/products/photo_6_2026-09-01_18-18-02.jpg',
  );
  final _video = TextEditingController(
    text: 'https://youtube.com/shorts/7cc55D-WSM0?feature=share',
  );
  final _desc = TextEditingController(
    text: '✨ ودّع الخدوش المزعجة بسيارتك في ثواني! قلم تصليح الخدوش الحل الأسرع لإرجاع لمعة السيارة الأصلية.',
  );
  final Map<String, bool> _cols = {
    'أسود': true,
    'فضي': true,
    'أحمر': true,
    'أصفر': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنتج',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categoriesList
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                      decoration: const InputDecoration(
                        labelText: 'القسم التابع له المنتج',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _price,
                            decoration: const InputDecoration(
                              labelText: 'السعر (د.ع)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _stock,
                            decoration: const InputDecoration(
                              labelText: 'الكمية بالمخزن',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _mainImg,
                      decoration: const InputDecoration(
                        labelText: 'رابط الصورة الرئيسية للمنتج',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _albumImgs,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'بقية صور الألبوم (مفصولة بفاصلة ,)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _video,
                      decoration: const InputDecoration(
                        labelText: 'رابط فيديو يوتيوب أو Shorts',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'الألوان المتوفرة:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: _cols.keys.map((k) {
                        return FilterChip(
                          label: Text(k),
                          selected: _cols[k]!,
                          onSelected: (v) => setState(() => _cols[k] = v),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _desc,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'الوصف والمواصفات',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          String mainUrl = _mainImg.text.trim();
                          List<String> list = [];
                          if (mainUrl.isNotEmpty) list.add(mainUrl);
                          List<String> extraList = _albumImgs.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          for (var e in extraList) {
                            if (!list.contains(e)) list.add(e);
                          }
                          List<String> selectedCols = _cols.entries
                              .where((e) => e.value)
                              .map((e) => e.key)
                              .toList();

                          await supabase.from('products').insert({
                            'name': _name.text,
                            'title': _name.text,
                            'category': _selectedCategory,
                            'price': double.tryParse(_price.text) ?? 0,
                            'stock': int.tryParse(_stock.text) ?? 0,
                            'image_url': mainUrl.isNotEmpty
                                ? mainUrl
                                : (list.isNotEmpty ? list.first : ''),
                            'images': list,
                            'video_url': _video.text.trim(),
                            'colors': selectedCols,
                            'description': _desc.text,
                          });
                          if (context.mounted) Navigator.pop(context, true);
                        },
                        child: const Text(
                          'حفظ ونشر المنتج',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 7. الحساب / لوحة الإدارة
// ==========================================
class AccountTabScreen extends StatelessWidget {
  final bool isGuest;
  final bool isAdmin;

  const AccountTabScreen({
    super.key,
    required this.isGuest,
    required this.isAdmin,
  });

  void _goToAuthLanding(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthLandingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الإدارة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: () => _goToAuthLanding(context),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        child: Icon(Icons.person, size: 45),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Chip(
                        label: Text(
                          'مدير المتجر',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.add_box, color: Colors.blue),
                    title: const Text(
                      'إضافة منتج جديد للمتجر',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.analytics, color: Colors.green),
                    title: const Text(
                      'إدارة الطلبات ولوحة الإحصائيات',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('متابعة الأرباح وطلبات الدروب شيبينغ'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      navKey.currentState?.switchTab(3);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _goToAuthLanding(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isGuest ? Icons.person_outline : Icons.account_circle,
                size: 70,
                color: Colors.blue.shade300,
              ),
              const SizedBox(height: 14),
              Text(
                isGuest
                    ? 'أهلاً بك في متجر الأمين'
                    : (user?.email ?? 'مرحباً بك'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isGuest
                    ? 'سجل دخولك لتتمكن من حفظ طلباتك ومتابعتها بسهولة'
                    : 'حسابك مسجل وجاهز للتسوق',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 240,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isGuest ? Colors.blue : Colors.red,
                  ),
                  icon: Icon(isGuest ? Icons.login : Icons.logout),
                  label: Text(
                    isGuest ? 'تسجيل الدخول / إنشاء حساب' : 'تسجيل الخروج',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () => _goToAuthLanding(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
