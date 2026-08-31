import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. الدالة الرئيسية وتهيئة Supabase
// ==========================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://idaxgihzqbgzvellxlxn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkYXhnaWh6cWJnenZlbGx4bHhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2NjI1MjAsImV4cCI6MjEwMzIzODUyMH0.CmZTgwnOx1iWArptCrFhRKP-nMAr2oUfKA0EBVruxFc',
  );

  runApp(const AlAminStoreApp());
}

// رمز الدخول السري للوحة تحكم المدير (1234)
const String ADMIN_SECRET_PIN = '1234';

// دالة التحقق من صحة رقم الهاتف العراقي (11 رقم يبدأ بـ 07)
bool isValidIraqiPhone(String phone) {
  final clean = phone.trim().replaceAll(' ', '');
  final RegExp regex = RegExp(r'^07[3-9]\d{8}$');
  return regex.hasMatch(clean);
}

// الجلسة الحالية
class UserSession {
  static String username = 'ضيف';
  static String email = '';
  static String phone = '';
  static String address = 'النجف الأشرف';
  static bool isGuest = true;

  static void reset() {
    username = 'ضيف';
    email = '';
    phone = '';
    address = 'النجف الأشرف';
    isGuest = true;
  }
}

// ==========================================
// إدارة حالة السلة والمفضلة (State Management)
// ==========================================
class CartManager {
  static final ValueNotifier<List<Map<String, dynamic>>> cartNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static List<Map<String, dynamic>> get items => cartNotifier.value;

  static void addProduct(Map<String, dynamic> product) {
    final List<Map<String, dynamic>> currentList = cartNotifier.value
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final String targetId = product['id']?.toString() ?? '';
    final int index = currentList.indexWhere(
      (item) => item['id']?.toString() == targetId,
    );

    if (index != -1) {
      final int currentQty =
          int.tryParse(currentList[index]['quantity'].toString()) ?? 1;
      currentList[index]['quantity'] = currentQty + 1;
    } else {
      currentList.add({
        'id': product['id'],
        'name': product['name']?.toString() ?? 'منتج',
        'price': (product['price'] is num)
            ? (product['price'] as num).toDouble()
            : double.tryParse(product['price'].toString()) ?? 0.0,
        'image_url': product['image_url']?.toString(),
        'quantity': 1,
      });
    }

    cartNotifier.value = currentList;
  }

  static void increaseQty(int index) {
    final List<Map<String, dynamic>> currentList = cartNotifier.value
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (index >= 0 && index < currentList.length) {
      final int currentQty =
          int.tryParse(currentList[index]['quantity'].toString()) ?? 1;
      currentList[index]['quantity'] = currentQty + 1;
      cartNotifier.value = currentList;
    }
  }

  static void decreaseQty(int index) {
    final List<Map<String, dynamic>> currentList = cartNotifier.value
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (index >= 0 && index < currentList.length) {
      final int currentQty =
          int.tryParse(currentList[index]['quantity'].toString()) ?? 1;
      if (currentQty > 1) {
        currentList[index]['quantity'] = currentQty - 1;
      } else {
        currentList.removeAt(index);
      }
      cartNotifier.value = currentList;
    }
  }

  static void removeItem(int index) {
    final List<Map<String, dynamic>> currentList = cartNotifier.value
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (index >= 0 && index < currentList.length) {
      currentList.removeAt(index);
      cartNotifier.value = currentList;
    }
  }

  static void clearCart() {
    cartNotifier.value = [];
  }

  static double get totalPrice {
    return cartNotifier.value.fold(0.0, (sum, item) {
      final double price = (item['price'] is num)
          ? (item['price'] as num).toDouble()
          : double.tryParse(item['price'].toString()) ?? 0.0;
      final int qty = (item['quantity'] is int)
          ? (item['quantity'] as int)
          : int.tryParse(item['quantity'].toString()) ?? 1;
      return sum + (price * qty);
    });
  }
}

class FavoritesManager {
  static final ValueNotifier<List<Map<String, dynamic>>> favNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static bool isFavorite(String id) {
    return favNotifier.value.any((item) => item['id']?.toString() == id);
  }

  static void toggleFavorite(Map<String, dynamic> product) {
    final List<Map<String, dynamic>> current = favNotifier.value
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final String pId = product['id']?.toString() ?? '';

    final index = current.indexWhere((item) => item['id']?.toString() == pId);
    if (index != -1) {
      current.removeAt(index);
    } else {
      current.add(product);
    }
    favNotifier.value = current;
  }
}

class AlAminStoreApp extends StatelessWidget {
  const AlAminStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'متجر الأمين',
      theme: ThemeData(
        fontFamily: 'Cairo',
        primaryColor: const Color(0xFFE53935),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          primary: const Color(0xFFE53935),
          secondary: const Color(0xFF1E88E5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      ),
      home: const AuthPage(),
    );
  }
}

// ==========================================
// 2. شاشة تسجيل الدخول وإنشاء الحساب
// ==========================================
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isSignUp = false;
  bool _isLoading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final supabase = Supabase.instance.client;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim().replaceAll(' ', '');

    if (email.isEmpty || password.isEmpty) {
      _showMsg('يرجى إدخال البريد الإلكتروني وكلمة المرور', Colors.redAccent);
      return;
    }

    if (_isSignUp && username.isEmpty) {
      _showMsg('يرجى إدخال اسم المستخدم', Colors.redAccent);
      return;
    }

    if (_isSignUp && phone.isNotEmpty && !isValidIraqiPhone(phone)) {
      _showMsg(
        'يرجى كتابة رقم عراقي صحيح (11 رقم يبدأ بـ 07)',
        Colors.redAccent,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        final check = await supabase
            .from('users')
            .select()
            .eq('email', email)
            .maybeSingle();

        if (check != null) {
          _showMsg('هذا الحساب مسجل بالفعل، يرجى تسجيل الدخول', Colors.orange);
          setState(() => _isSignUp = false);
          return;
        }

        await supabase.from('users').insert({
          'username': username,
          'email': email,
          'password': _hashPassword(password),
          'phone': phone.isNotEmpty ? phone : null,
        });

        UserSession.username = username;
        UserSession.email = email;
        UserSession.phone = phone;
        UserSession.isGuest = false;

        _showMsg('تم إنشاء الحساب بنجاح! 🎉', Colors.green);
      } else {
        final user = await supabase
            .from('users')
            .select()
            .eq('email', email)
            .maybeSingle();

        if (user == null) {
          _showMsg(
            'الحساب غير موجود! يرجى إنشاء حساب جديد أولاً',
            Colors.redAccent,
          );
          return;
        }

        if (user['password'] != _hashPassword(password)) {
          _showMsg('كلمة المرور غير صحيحة!', Colors.redAccent);
          return;
        }

        UserSession.username = user['username'] ?? 'مستخدم';
        UserSession.email = email;
        UserSession.phone = user['phone'] ?? '';
        UserSession.isGuest = false;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationShell()),
      );
    } catch (e) {
      _showMsg('خطأ في الاتصال: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loginAsGuest() {
    UserSession.reset();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationShell()),
    );
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      size: 48,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'متجر الأمين',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp
                        ? 'إنشاء حساب جديد للتسوق السريع'
                        : 'تسجيل الدخول إلى حسابك',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isSignUp) ...[
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'اسم المستخدم',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'البريد الإلكتروني',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isSignUp) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'رقم الهاتف (0780xxxxxxx)',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isSignUp ? 'إنشاء الحساب' : 'تسجيل الدخول',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                          : 'ليس لديك حساب؟ إنشاء حساب جديد',
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginAsGuest,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.visibility_outlined,
                        color: Color(0xFF475569),
                      ),
                      label: const Text(
                        'التصفح السريع كضيف 👁️',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 14,
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
    );
  }
}

// ==========================================
// 3. شريط الملاحة الرئيسي
// ==========================================
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreenTab(),
    const CategoriesTab(),
    const FavoritesTab(),
    const CartScreenTab(),
    const ProfilePageTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: CartManager.cartNotifier,
          builder: (context, cartItems, child) {
            final int totalCartCount = cartItems.fold(0, (sum, item) {
              return sum + (int.tryParse(item['quantity'].toString()) ?? 1);
            });

            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFE53935),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'الرئيسية',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined),
                  activeIcon: Icon(Icons.grid_view),
                  label: 'الأقسام',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_outline),
                  activeIcon: Icon(Icons.favorite),
                  label: 'المفضلة',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_outlined),
                      if (totalCartCount > 0)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$totalCartCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'السلة',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'الحساب',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// نافذة إتمام الطلب المشتركة (تأكيد فوري أو سلة)
// ==========================================
void showDirectCheckoutDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> orderItems,
  required double totalPrice,
  VoidCallback? onOrderSuccess,
}) {
  final phoneCtrl = TextEditingController(text: UserSession.phone);
  final addressCtrl = TextEditingController(text: UserSession.address);
  String selectedCity = 'النجف الأشرف';
  String errorMsg = '';
  bool isSubmitting = false;

  final cities = [
    'النجف الأشرف',
    'بغداد',
    'البصرة',
    'كربلاء المقدسة',
    'أربيل',
    'بابل',
    'الموصل',
    'السليمانية',
    'كركوك',
    'ديالى',
    'الأنبار',
    'ذي قار',
    'ميسان',
    'المثنى',
    'القادسية',
    'واسط',
    'صلاح الدين',
    'دهوك',
  ];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.flash_on, color: Colors.orange),
              SizedBox(width: 6),
              Text(
                'تأكيد الطلب 🚚',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'المبلغ الكلي:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '$totalPrice د.ع',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'المحافظة:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  items: cities
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(
                    () => selectedCity = val ?? 'النجف الأشرف',
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'العنوان التفصيلي / نقطة دالة:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    hintText: 'مثال: حي الأمير، قرب جامع...',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'رقم هاتف المستلم (11 رقم):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: InputDecoration(
                    hintText: '0780xxxxxxx',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMsg,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final inputPhone = phoneCtrl.text.trim().replaceAll(
                        ' ',
                        '',
                      );
                      final inputAddress = addressCtrl.text.trim();

                      if (!isValidIraqiPhone(inputPhone)) {
                        setDialogState(() {
                          errorMsg =
                              '❌ يرجى إدخال رقم عراقي صحيح (11 رقم يبدأ بـ 07)';
                        });
                        return;
                      }

                      if (inputAddress.isEmpty) {
                        setDialogState(() {
                          errorMsg = '❌ يرجى كتابة العنوان أو أقرب نقطة دالة';
                        });
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      final fullAddress = '$selectedCity - $inputAddress';

                      try {
                        final supabase = Supabase.instance.client;
                        final res = await supabase.from('orders').insert({
                          'customer_name': UserSession.username.isNotEmpty
                              ? UserSession.username
                              : 'ضيف',
                          'customer_phone': '$inputPhone ($fullAddress)',
                          'items': orderItems,
                          'total_amount': totalPrice,
                          'total_price': totalPrice,
                          'status': 'قيد الانتظار',
                        }).select();

                        final dynamic createdOrderId = res.isNotEmpty
                            ? res.first['id']
                            : 'جديد';

                        if (onOrderSuccess != null) onOrderSuccess();
                        Navigator.pop(ctx);
                        _showOrderSuccessReceipt(
                          context,
                          createdOrderId,
                          totalPrice,
                          fullAddress,
                          inputPhone,
                        );
                      } catch (e) {
                        setDialogState(() {
                          isSubmitting = false;
                          errorMsg = 'خطأ أثناء الطلب: $e';
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('تأكيد وإرسال الطلب ⚡'),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showOrderSuccessReceipt(
  BuildContext context,
  dynamic orderId,
  double total,
  String address,
  String phone,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 55),
            SizedBox(height: 8),
            Text(
              'تم استلام طلبك بنجاح!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رقم الطلب: #$orderId',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
            const Divider(),
            Text('العميل: ${UserSession.username}'),
            Text('رقم الهاتف: $phone'),
            Text('عنوان التوصيل: $address'),
            const SizedBox(height: 8),
            Text(
              'المبلغ الإجمالي: $total د.ع',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'شكراً لثقتكم بمتجر الأمين! سيتم الاتصال بكم هاتفياً لتسليم الطلب.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('متابعة التسوق'),
            ),
          ),
        ],
      ),
    ),
  );
}

// ==========================================
// 4. الواجهة الرئيسية
// ==========================================
class HomeScreenTab extends StatefulWidget {
  const HomeScreenTab({super.key});

  @override
  State<HomeScreenTab> createState() => _HomeScreenTabState();
}

class _HomeScreenTabState extends State<HomeScreenTab> {
  final supabase = Supabase.instance.client;
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  final List<Map<String, dynamic>> _quickCategories = [
    {'name': 'الكل', 'icon': Icons.apps, 'color': const Color(0xFFE53935)},
    {
      'name': 'موبايلات',
      'icon': Icons.phone_iphone,
      'color': const Color(0xFF2196F3),
    },
    {
      'name': 'لابتوبات',
      'icon': Icons.laptop,
      'color': const Color(0xFF4CAF50),
    },
    {'name': 'شاشات', 'icon': Icons.tv, 'color': const Color(0xFFFF9800)},
    {'name': 'عطور', 'icon': Icons.spa, 'color': const Color(0xFFE91E63)},
    {
      'name': 'تخفيضات',
      'icon': Icons.local_offer,
      'color': const Color(0xFF9C27B0),
    },
  ];

  void _addToCart(Map<String, dynamic> product) {
    CartManager.addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة (${product['name']}) إلى السلة 🛒'),
        duration: const Duration(milliseconds: 600),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _buyNowDirect(Map<String, dynamic> product) {
    final double price = (product['price'] is num)
        ? (product['price'] as num).toDouble()
        : double.tryParse(product['price'].toString()) ?? 0.0;

    final singleItemOrder = [
      {
        'id': product['id'],
        'name': product['name']?.toString() ?? 'منتج',
        'price': price,
        'image_url': product['image_url']?.toString(),
        'quantity': 1,
      },
    ];

    showDirectCheckoutDialog(
      context: context,
      orderItems: singleItemOrder,
      totalPrice: price,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(
            top: 35,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن منتج في متجر الأمين...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFFE53935),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'التوصيل متاح لكل العراق 🇮🇶',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'أهلاً، ${UserSession.username}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E88E5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'عروض متجر الأمين 🔥',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'تخفيضات كبرى وشراء فوري ⚡',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'توصيل فوري مباشر لباب البيت',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: 50,
                      color: Colors.white30,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'الأقسام الرئيسية',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickCategories.length,
                itemBuilder: (context, index) {
                  final cat = _quickCategories[index];
                  final isSelected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(
                      () => _selectedCategory = cat['name'] as String,
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (cat['color'] as Color)
                                  : (cat['color'] as Color).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              color: isSelected
                                  ? Colors.white
                                  : (cat['color'] as Color),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'المنتجات المتوفرة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase.from('products').select(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('خطأ في جلب المنتجات: ${snapshot.error}'),
                  );
                }

                final products = snapshot.data ?? [];
                final filtered = products.where((p) {
                  final name = (p['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('لا توجد منتجات مطابقة حالياً'),
                    ),
                  );
                }

                return ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: FavoritesManager.favNotifier,
                  builder: (context, favList, child) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio:
                                0.54, // زيادة الارتفاع لضمان وضوح كامل للأزرار
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final String pId = item['id']?.toString() ?? '';
                        final bool isFav = FavoritesManager.isFavorite(pId);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(
                                  product: item,
                                  onAddToCart: () => _addToCart(item),
                                  onBuyNow: () => _buyNowDirect(item),
                                ),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.white,
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        color: const Color(0xFFF8FAFC),
                                        child:
                                            item['image_url'] != null &&
                                                item['image_url']
                                                    .toString()
                                                    .isNotEmpty
                                            ? Image.network(
                                                item['image_url'],
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.devices,
                                                      color: Colors.grey,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.devices,
                                                size: 45,
                                                color: Colors.grey,
                                              ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.white
                                              .withOpacity(0.9),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              isFav
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              size: 16,
                                              color: isFav
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            onPressed: () =>
                                                FavoritesManager.toggleFavorite(
                                                  item,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['price']} د.ع',
                                        style: const TextStyle(
                                          color: Color(0xFFE53935),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // 1. زر الشراء الفوري ⚡
                                      SizedBox(
                                        width: double.infinity,
                                        height: 32,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _buyNowDirect(item),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFE53935,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.flash_on,
                                            size: 15,
                                          ),
                                          label: const Text(
                                            'شراء الآن ⚡',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // 2. زر إضافة للسلة 🛒
                                      SizedBox(
                                        width: double.infinity,
                                        height: 30,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _addToCart(item),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF1E88E5,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFBBDEFB),
                                            ),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.add_shopping_cart,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            'أضف للسلة 🛒',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. صفحة تفاصيل المنتج المستقلة مع الشراء الفوري
// ==========================================
class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            product['name'] ?? 'تفاصيل المنتج',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0.5,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 260,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child:
                          product['image_url'] != null &&
                              product['image_url'].toString().isNotEmpty
                          ? Image.network(
                              product['image_url'],
                              fit: BoxFit.contain,
                            )
                          : const Icon(
                              Icons.devices,
                              size: 80,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      product['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${product['price']} د.ع',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53935),
                      ),
                    ),
                    const Divider(height: 30),
                    const Text(
                      'المواصفات والضمان:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• منتج أصلي ومضمون من متجر الأمين 100%.\n• شحن وتوصيل فوري مباشر لباب المنزل.\n• إمكانية الفحص والمعاينة عند الاستلام.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.8,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onBuyNow();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.flash_on),
                        label: const Text(
                          'شراء فوري ⚡',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        onAddToCart();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E88E5),
                        side: const BorderSide(color: Color(0xFF90CAF9)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text(
                        'للسلة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. تبويب التصنيفات
// ==========================================
class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'title': 'الموبايلات والأجهزة اللوحية', 'icon': Icons.phone_android},
      {'title': 'اللابتوبات والكمبيوتر', 'icon': Icons.laptop_chromebook},
      {'title': 'الشاشات والتلفزيونات', 'icon': Icons.tv},
      {'title': 'العطور ومستحضرات التجميل', 'icon': Icons.brush},
      {'title': 'الأجهزة المنزلية والمطبخ', 'icon': Icons.kitchen},
      {'title': 'الساعات والإكسسوارات', 'icon': Icons.watch},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'أقسام المتجر',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFEBEE),
              child: Icon(
                cat['icon'] as IconData,
                color: const Color(0xFFE53935),
              ),
            ),
            title: Text(
              cat['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey,
            ),
            onTap: () {},
          );
        },
      ),
    );
  }
}

// ==========================================
// 7. تبويب المفضلة
// ==========================================
class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'قائمة المفضلة ❤️',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: FavoritesManager.favNotifier,
        builder: (context, favList, child) {
          if (favList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 70,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'لا توجد منتجات في المفضلة حالياً',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favList.length,
            itemBuilder: (context, index) {
              final item = favList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item['image_url'] != null
                        ? Image.network(
                            item['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.devices),
                          )
                        : const Icon(Icons.devices),
                  ),
                  title: Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${item['price']} د.ع',
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: Color(0xFFE53935),
                        ),
                        onPressed: () {
                          CartManager.addProduct(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تمت إضافة ${item['name']} إلى السلة',
                              ),
                              duration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () => FavoritesManager.toggleFavorite(item),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 8. تبويب السلة
// ==========================================
class CartScreenTab extends StatefulWidget {
  const CartScreenTab({super.key});

  @override
  State<CartScreenTab> createState() => _CartScreenTabState();
}

class _CartScreenTabState extends State<CartScreenTab> {
  void _checkoutCart() {
    final cartList = CartManager.items;
    if (cartList.isEmpty) return;

    showDirectCheckoutDialog(
      context: context,
      orderItems: cartList,
      totalPrice: CartManager.totalPrice,
      onOrderSuccess: () {
        CartManager.clearCart();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'سلة التسوّق',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: CartManager.cartNotifier,
        builder: (context, cartItems, child) {
          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 70,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'السلة فارغة حالياً',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final String name = item['name']?.toString() ?? 'منتج';
                    final double price = (item['price'] is num)
                        ? (item['price'] as num).toDouble()
                        : double.tryParse(item['price'].toString()) ?? 0.0;
                    final int qty = (item['quantity'] is int)
                        ? (item['quantity'] as int)
                        : int.tryParse(item['quantity'].toString()) ?? 1;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  item['image_url'] != null &&
                                      item['image_url'].toString().isNotEmpty
                                  ? Image.network(
                                      item['image_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(
                                        Icons.devices,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.devices,
                                      color: Colors.grey,
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$price د.ع',
                                    style: const TextStyle(
                                      color: Color(0xFFE53935),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      CartManager.decreaseQty(index),
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      CartManager.increaseQty(index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      CartManager.removeItem(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'المجموع الكلي:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${CartManager.totalPrice} د.ع',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _checkoutCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'إتمام وإرسال الطلب',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
}

// ==========================================
// 9. تبويب الحساب وقفل لوحة تحكم المدير برمز أمان
// ==========================================
class ProfilePageTab extends StatefulWidget {
  const ProfilePageTab({super.key});

  @override
  State<ProfilePageTab> createState() => _ProfilePageTabState();
}

class _ProfilePageTabState extends State<ProfilePageTab> {
  final supabase = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = UserSession.isGuest ? '' : UserSession.username;
    _phoneController.text = UserSession.isGuest ? '' : UserSession.phone;
  }

  void _logout() {
    UserSession.reset();
    CartManager.clearCart();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
      (route) => false,
    );
  }

  void _openAdminWithPassword() {
    final pinCtrl = TextEditingController();
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPinState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'دخول لوحة المدير 🔒',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أدخل رمز الأمان المخصص للمدير (الرمز الافتراضي: 1234):',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (pinCtrl.text.trim() == ADMIN_SECRET_PIN) {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardPage(),
                      ),
                    );
                  } else {
                    setPinState(() {
                      error = 'الرمز السري غير صحيح!';
                    });
                  }
                },
                child: const Text('دخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (UserSession.isGuest) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('يرجى إنشاء حساب أولاً')));
      return;
    }

    final phone = _phoneController.text.trim().replaceAll(' ', '');
    if (phone.isNotEmpty && !isValidIraqiPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة رقم عراقي صحيح (11 رقم يبدأ بـ 07)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await supabase
          .from('users')
          .update({
            'username': _nameController.text.trim(),
            'phone': phone.isNotEmpty ? phone : null,
          })
          .eq('email', UserSession.email);

      UserSession.username = _nameController.text.trim();
      UserSession.phone = phone;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ وتحديث بياناتك بنجاح! ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'حسابي',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFE53935)),
            tooltip: 'خروج',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFFFEBEE),
              child: const Icon(
                Icons.person,
                size: 45,
                color: Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              UserSession.username,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (!UserSession.isGuest)
              Text(
                UserSession.email,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 16),

            // زر لوحة تحكم المدير
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF1E88E5),
                  size: 28,
                ),
                title: const Text(
                  'لوحة إدارة متجر الأمين 🔒',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                subtitle: const Text(
                  'تتطلب رمز أمان للمدير (إدارة وتعديل المنتجات والطلبات)',
                  style: TextStyle(fontSize: 11),
                ),
                trailing: const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: Color(0xFF1E88E5),
                ),
                onTap: _openAdminWithPassword,
              ),
            ),
            const SizedBox(height: 10),

            // زر سجل طلباتي
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFFE53935),
                  size: 24,
                ),
                title: const Text(
                  'سجل طلباتي السابقة 📦',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserOrdersHistoryPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم المستخدم',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف (0780xxxxxxx)',
                counterText: '',
                prefixIcon: const Icon(Icons.phone_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ التعديلات',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
// 10. شاشة سجل طلبات الزبون
// ==========================================
class UserOrdersHistoryPage extends StatelessWidget {
  const UserOrdersHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'سجل طلباتي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0.5,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: supabase
              .from('orders')
              .select()
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('خطأ: ${snapshot.error}'));
            }

            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return const Center(child: Text('لا توجد طلبات سابقة'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final status = order['status']?.toString() ?? 'قيد الانتظار';

                Color statusColor = Colors.orange;
                if (status.contains('توصيل') || status.contains('delivery'))
                  statusColor = Colors.blue;
                if (status.contains('تم') ||
                    status.contains('delivered') ||
                    status.contains('مكتمل'))
                  statusColor = Colors.green;
                if (status.contains('ملغي') || status.contains('cancel'))
                  statusColor = Colors.red;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'طلب #${order['id'].toString().substring(0, order['id'].toString().length > 8 ? 8 : order['id'].toString().length)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Text(
                          'بيانات التوصيل: ${order['customer_phone'] ?? "غير متوفر"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'المجموع: ${order['total_amount'] ?? order['total_price']} د.ع',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// 11. لوحة تحكم وإدارة المتجر (Admin Dashboard الشاملة)
// ==========================================
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _updateOrderStatus(dynamic orderId, String newStatus) async {
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId.toString());
      setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث الطلب إلى: $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteOrder(dynamic orderId) async {
    try {
      await supabase.from('orders').delete().eq('id', orderId.toString());
      setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الطلب 🗑️'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteProduct(dynamic productId) async {
    try {
      await supabase.from('products').delete().eq('id', productId);
      setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف المنتج بنجاح 🗑️'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showAddEditProductDialog({Map<String, dynamic>? existingProduct}) {
    final nameCtrl = TextEditingController(
      text: existingProduct != null ? existingProduct['name'] : '',
    );
    final priceCtrl = TextEditingController(
      text: existingProduct != null ? existingProduct['price'].toString() : '',
    );
    final imageCtrl = TextEditingController(
      text: existingProduct != null ? existingProduct['image_url'] ?? '' : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            existingProduct != null
                ? 'تعديل بيانات المنتج'
                : 'إضافة منتج جديد للمتجر',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المنتج'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'السعر (د.ع)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رابط الصورة (URL)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final img = imageCtrl.text.trim();

                if (name.isNotEmpty && price > 0) {
                  if (existingProduct != null) {
                    await supabase
                        .from('products')
                        .update({
                          'name': name,
                          'price': price,
                          'image_url': img.isNotEmpty ? img : null,
                        })
                        .eq('id', existingProduct['id']);
                  } else {
                    await supabase.from('products').insert({
                      'name': name,
                      'price': price,
                      'image_url': img.isNotEmpty ? img : null,
                    });
                  }
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حفظ المنتج بنجاح! 🎉'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'لوحة تحكم متجر الأمين',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.receipt_long), text: 'الطلبات الواردة'),
              Tab(icon: Icon(Icons.inventory_2), text: 'إدارة المنتجات'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // 1. تبويب الطلبات
            FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase
                  .from('orders')
                  .select()
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('لا توجد طلبات واردة حالياً'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final dynamic id = order['id'];
                    final status =
                        order['status']?.toString() ?? 'قيد الانتظار';
                    final displayId = id.toString().length > 8
                        ? id.toString().substring(0, 8)
                        : id.toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'طلب رقم #$displayId',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_forever,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  tooltip: 'حذف الطلب',
                                  onPressed: () => _deleteOrder(id),
                                ),
                              ],
                            ),
                            Text(
                              '💰 المبلغ الإجمالي: ${order['total_amount'] ?? order['total_price']} د.ع',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE53935),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '👤 العميل: ${order['customer_name'] ?? "ضيف"}',
                            ),
                            Text(
                              '📍 بيانات التوصيل: ${order['customer_phone'] ?? "غير متوفر"}',
                            ),
                            Text(
                              '📌 الحالة الحالية: $status',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                            const Divider(height: 16),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _updateOrderStatus(id, 'جاري التوصيل 🚚'),
                                  child: const Text(
                                    'توصيل 🚚',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed: () => _updateOrderStatus(
                                    id,
                                    'تم التسليم بنجاح ✅',
                                  ),
                                  child: const Text(
                                    'تسليم ✅',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _updateOrderStatus(id, 'ملغي ❌'),
                                  child: const Text(
                                    'إلغاء ❌',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // 2. تبويب إدارة المنتجات
            Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: const Color(0xFFE53935),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'إضافة منتج',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _showAddEditProductDialog(),
              ),
              body: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase.from('products').select(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return const Center(child: Text('لا توجد منتجات مسجلة'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: p['image_url'] != null
                                ? Image.network(
                                    p['image_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.devices),
                                  )
                                : const Icon(Icons.devices),
                          ),
                          title: Text(
                            p['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${p['price']} د.ع',
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                onPressed: () => _showAddEditProductDialog(
                                  existingProduct: p,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _deleteProduct(p['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
