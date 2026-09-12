import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: 'https://idaxgihzqbgzvellxlxn.supabase.co',
      anonKey: 'sb_publishable_5upJjPyzgNRV9Rk-1WeWjg_RffVxRMn',
    );
  } catch (_) {}
  _loadCartFromStorage();
  _loadWishlistFromStorage();
  _loadFavoriteBannersFromStorage();
  _loadBannerMessagesFromStorage();
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;
const String kAdminEmail = 'gametrailerengilish@gmail.com';
const String kWhatsAppNumber = '9647700000000';
const double kDeliveryFee = 5000.0;

final ValueNotifier<List<Map<String, dynamic>>> cartNotifier = ValueNotifier(
  [],
);
final ValueNotifier<List<Map<String, dynamic>>> wishlistNotifier =
    ValueNotifier([]);
final ValueNotifier<List<String>> favoriteBannerNotifier = ValueNotifier([]);
final ValueNotifier<List<String>> bannerMessagesNotifier = ValueNotifier([]);

// Notifier للإشعارات غير المقروءة للزبون
final ValueNotifier<int> unreadNotificationsCount = ValueNotifier(0);
// Notifier للرسائل الواردة الجديدة للمدير
final ValueNotifier<int> unreadAdminMessagesCount = ValueNotifier(0);

// Notifier عالمي للتحكم بعرض شاشة تفاصيل المنتج
final ValueNotifier<Map<String, dynamic>?> selectedProductNotifier =
    ValueNotifier(null);

void _loadCartFromStorage() {
  try {
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('shared_cart')) {
      final decodedBytes = base64Url.decode(
        uri.queryParameters['shared_cart']!,
      );
      final decodedJson = utf8.decode(decodedBytes);
      final List decodedList = jsonDecode(decodedJson);
      final cartFromUrl = decodedList
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      cartNotifier.value = cartFromUrl;
      _saveCartToStorage(cartFromUrl);
      return;
    }

    final raw = html.window.localStorage['user_cart'];
    if (raw != null && raw.isNotEmpty) {
      final List decoded = jsonDecode(raw);
      cartNotifier.value = decoded
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  } catch (_) {}
}

void _saveCartToStorage(List<Map<String, dynamic>> items) {
  try {
    html.window.localStorage['user_cart'] = jsonEncode(items);
  } catch (_) {}
}

void _loadWishlistFromStorage() {
  try {
    final raw = html.window.localStorage['user_wishlist'];
    if (raw != null && raw.isNotEmpty) {
      final List decoded = jsonDecode(raw);
      wishlistNotifier.value = decoded
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  } catch (_) {}
}

void _saveWishlistToStorage(List<Map<String, dynamic>> items) {
  try {
    html.window.localStorage['user_wishlist'] = jsonEncode(items);
  } catch (_) {}
}

void _loadFavoriteBannersFromStorage() {
  try {
    final raw = html.window.localStorage['favorite_store_banners'];
    if (raw != null && raw.isNotEmpty) {
      final List decoded = jsonDecode(raw);
      favoriteBannerNotifier.value = decoded.map((e) => e.toString()).toList();
    }
  } catch (_) {}
}

void _saveFavoriteBannersToStorage(List<String> items) {
  try {
    html.window.localStorage['favorite_store_banners'] = jsonEncode(items);
  } catch (_) {}
}

void _loadBannerMessagesFromStorage() {
  try {
    final raw = html.window.localStorage['store_banners_list'];
    if (raw != null && raw.isNotEmpty) {
      final List decoded = jsonDecode(raw);
      bannerMessagesNotifier.value = decoded
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
  } catch (_) {}
}

void _saveBannerMessagesToStorage(List<String> items) {
  try {
    html.window.localStorage['store_banners_list'] = jsonEncode(items);
  } catch (_) {}
}

Future<List<String>> _loadSharedBannerMessages() async {
  try {
    final response = await supabase
        .from('store_banners')
        .select('message, expires_at')
        .order('created_at', ascending: false)
        .limit(20);
    return (response as List)
        .where((item) {
          final expiresAt = DateTime.tryParse(
            item['expires_at']?.toString() ?? '',
          );
          return expiresAt == null || expiresAt.isAfter(DateTime.now());
        })
        .map((item) => item['message'].toString())
        .where((message) => message.trim().isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}

Future<bool> _saveSharedBannerMessage(
  String message, {
  DateTime? expiresAt,
}) async {
  try {
    await supabase.from('store_banners').insert({
      'message': message,
      'expires_at': expiresAt?.toUtc().toIso8601String(),
    });
    return true;
  } catch (_) {
    return false;
  }
}

Future<List<Map<String, dynamic>>> _loadBannerRecords() async {
  try {
    final response = await supabase
        .from('store_banners')
        .select('id, message, expires_at, created_at')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  } catch (_) {
    return [];
  }
}

Future<String?> _pickImageAsDataUrl() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();
  await input.onChange.first;
  final file = input.files?.first;
  if (file == null) return null;
  final reader = html.FileReader();
  reader.readAsDataUrl(file);
  await reader.onLoad.first;
  return reader.result?.toString();
}

Future<List<String>> _pickImagesAsDataUrls() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = true;
  input.click();
  await input.onChange.first;
  final files = input.files ?? <html.File>[];
  final images = <String>[];
  for (final file in files) {
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    final result = reader.result?.toString();
    if (result != null && result.isNotEmpty) images.add(result);
  }
  return images;
}

// دالة عامة لإظهار نافذة نجاح الطلب ومشاركة التفاصيل عبر الواتساب
void _showOrderSuccessDialog(
  BuildContext context,
  String product,
  double price,
  String name,
  String phone,
  String prov,
  String addr,
  String color,
) {
  bool hasColor = color.isNotEmpty && color != 'قياسي' && color != 'افتراضي';

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 30),
          SizedBox(width: 10),
          Text('🎉 تم إرسال طلبك بنجاح!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'شكراً لاختيارك متجر الأمين. تم تسجيل طلبك وإرساله للإدارة فوراً.',
          ),
          const SizedBox(height: 10),
          Text('📦 المنتج: $product'),
          if (hasColor) Text('🎨 اللون: $color'),
          Text('💰 المبلغ الإجمالي: $price د.ع'),
          Text('📍 العنوان: $prov - $addr'),
          const SizedBox(height: 10),
          const Text('يمكنك مشاركة تفاصيل طلبك أو الاحتفاظ بها:'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إغلاق'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.share, size: 18),
          label: const Text('مشاركة التفاصيل عبر الواتساب'),
          onPressed: () {
            String detailsText =
                '🎉 تفاصيل طلبي من متجر الأمين:\n- المنتج: $product\n';
            if (hasColor) detailsText += '- اللون: $color\n';
            detailsText +=
                '- المبلغ: $price د.ع\n- الاسم: $name\n- الهاتف: $phone\n- العنوان: $prov - $addr\nشكراً لخدمتكم الفائقة!';

            final msg = Uri.encodeComponent(detailsText);
            html.window.open('https://wa.me/?text=$msg', '_blank');
          },
        ),
      ],
    ),
  );
}

final GlobalKey<MainNavigationScreenState> navKey =
    GlobalKey<MainNavigationScreenState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  int _getSavedTab() {
    final saved = html.window.localStorage['current_tab'];
    if (saved != null) {
      final val = int.tryParse(saved);
      if (val == 3 || val == 4) return 3;
      if (val != null && val >= 0 && val <= 2) return val;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'متجر الأمين',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          primary: const Color(0xFF1565C0),
          secondary: const Color(0xFF4FC3F7),
          tertiary: const Color(0xFFFFB74D),
          surface: const Color(0xFFFFFFFF),
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF7FCFB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4E9EE), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: SplashScreen(initialIndex: _getSavedTab()),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final int initialIndex;

  const SplashScreen({super.key, required this.initialIndex});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(
            key: navKey,
            isGuest: supabase.auth.currentUser == null,
            initialIndex: widget.initialIndex,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1976D2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_rounded, color: Colors.amber, size: 64),
            SizedBox(height: 14),
            Text(
              'متجر الأمين',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 18),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }
}

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
      final iframe = html.IFrameElement()
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

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _videoCtrl;
  late String _selectedCategory;
  late bool _isOutOfStock;
  bool _isLoading = false;
  final List<String> _images = [];

  final List<String> _categories = [
    'عروض وتخفيضات',
    'إلكترونيات',
    'أدوات السيارات',
    'أجهزة المنزل',
    'أجهزة المطبخ',
    'أدوات مطبخ',
    'أجهزة العناية',
    'منتجات العناية',
    'ألعاب أطفال',
    'عدد وأدوات',
    'أدوات منزلية',
    'إنارة وإضاءة',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.product['name'] ?? widget.product['title'] ?? '',
    );
    _priceCtrl = TextEditingController(
      text: widget.product['price']?.toString() ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.product['description'] ?? '',
    );
    _imageCtrl = TextEditingController(
      text: widget.product['image_url'] ?? widget.product['image'] ?? '',
    );
    final mainImage = _imageCtrl.text.trim();
    if (mainImage.isNotEmpty) _images.add(mainImage);
    if (widget.product['images'] is List) {
      for (final image in widget.product['images']) {
        final value = image.toString().trim();
        if (value.isNotEmpty && !_images.contains(value)) _images.add(value);
      }
    }
    _videoCtrl = TextEditingController(text: widget.product['video_url'] ?? '');
    _selectedCategory = widget.product['category'] ?? 'إلكترونيات';
    _isOutOfStock =
        widget.product['out_of_stock'] == true ||
        widget.product['is_out_of_stock'] == true;
  }

  Future<void> _updateProduct() async {
    final name = _nameCtrl.text.trim();
    final priceStr = _priceCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final imgUrl = _imageCtrl.text.trim();
    final videoUrl = _videoCtrl.text.trim();

    if (name.isEmpty || priceStr.isEmpty) return;
    final double? price = double.tryParse(priceStr);
    if (price == null) return;
    final images = List<String>.from(_images);
    if (imgUrl.isNotEmpty && !images.contains(imgUrl)) images.insert(0, imgUrl);
    if (images.isEmpty) images.add('');

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('products')
          .update({
            'name': name,
            'title': name,
            'price': price,
            'description': desc,
            'image_url': images.first,
            'images': images,
            'video_url': videoUrl,
            'category': _selectedCategory,
          })
          .eq('id', widget.product['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تعديل المنتج بنجاح'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التعديل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل المنتج')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'السعر (د.ع) *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _categories.contains(_selectedCategory)
                    ? _selectedCategory
                    : 'إلكترونيات',
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                decoration: const InputDecoration(
                  labelText: 'القسم *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                title: const Text(
                  'نفاد الكمية (تعطيل الشراء)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: _isOutOfStock,
                activeColor: Colors.red,
                onChanged: (v) => setState(() => _isOutOfStock = v),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'رابط صورة المنتج (URL)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('اختيار صور متعددة من الجهاز'),
                onPressed: () async {
                  final images = await _pickImagesAsDataUrls();
                  if (images.isNotEmpty && mounted) {
                    setState(() {
                      _images.addAll(
                        images.where((image) => !_images.contains(image)),
                      );
                      _imageCtrl.text = _images.first;
                    });
                  }
                },
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'الصورة الأولى هي الرئيسية وتظهر على بطاقة المنتج',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => setState(() {
                        final image = _images.removeAt(index);
                        _images.insert(0, image);
                        _imageCtrl.text = image;
                      }),
                      child: Container(
                        width: 84,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: index == 0
                                ? const Color(0xFF1976D2)
                                : Colors.grey.shade300,
                            width: index == 0 ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(_images[index], fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _videoCtrl,
                decoration: const InputDecoration(
                  labelText: 'رابط فيديو يوتيوب (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'وصف ومواصفات المنتج',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _updateProduct,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'حفظ التعديلات',
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
    );
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  String _selectedCategory = 'إلكترونيات';
  bool _isOutOfStock = false;
  bool _isLoading = false;
  final List<String> _images = [];

  final List<String> _categories = [
    'عروض وتخفيضات',
    'إلكترونيات',
    'أدوات السيارات',
    'أجهزة المنزل',
    'أجهزة المطبخ',
    'أدوات مطبخ',
    'أجهزة العناية',
    'منتجات العناية',
    'ألعاب أطفال',
    'عدد وأدوات',
    'أدوات منزلية',
    'إنارة وإضاءة',
  ];

  Future<void> _saveProduct() async {
    final name = _nameCtrl.text.trim();
    final priceStr = _priceCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final imgUrl = _imageCtrl.text.trim();
    final videoUrl = _videoCtrl.text.trim();

    if (name.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المنتج والسعر على الأقل')),
      );
      return;
    }

    final double? price = double.tryParse(priceStr);
    if (price == null) return;
    final images = List<String>.from(_images);
    if (imgUrl.isNotEmpty && !images.contains(imgUrl)) images.insert(0, imgUrl);
    if (images.isEmpty) images.add('');

    setState(() => _isLoading = true);
    try {
      await supabase.from('products').insert({
        'name': name,
        'title': name,
        'price': price,
        'description': desc,
        'image_url': images.first,
        'images': images,
        'video_url': videoUrl,
        'category': _selectedCategory,
        'colors': ['أسود', 'فضي', 'أبيض'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إضافة المنتج بنجاح!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'السعر (د.ع) *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                decoration: const InputDecoration(
                  labelText: 'القسم *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                title: const Text(
                  'نفاد الكمية (تعطيل الشراء)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: _isOutOfStock,
                activeColor: Colors.red,
                onChanged: (v) => setState(() => _isOutOfStock = v),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'رابط صورة المنتج (URL)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('اختيار صور متعددة من الجهاز'),
                onPressed: () async {
                  final images = await _pickImagesAsDataUrls();
                  if (images.isNotEmpty && mounted) {
                    setState(() {
                      _images.addAll(
                        images.where((image) => !_images.contains(image)),
                      );
                      _imageCtrl.text = _images.first;
                    });
                  }
                },
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'الصورة الأولى هي الرئيسية وتظهر على بطاقة المنتج',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => setState(() {
                        final image = _images.removeAt(index);
                        _images.insert(0, image);
                        _imageCtrl.text = image;
                      }),
                      child: Container(
                        width: 84,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: index == 0
                                ? const Color(0xFF1976D2)
                                : Colors.grey.shade300,
                            width: index == 0 ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(_images[index], fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _videoCtrl,
                decoration: const InputDecoration(
                  labelText: 'رابط فيديو يوتيوب (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'وصف ومواصفات المنتج',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
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
    );
  }
}

// شاشة تسجيل الدخول وإنشاء الحساب
class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  final _nameController = TextEditingController();
  final _inputController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  Future<void> _submitAuth() async {
    final input = _inputController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final fullName = _nameController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إدخال البريد الإلكتروني أو رقم الهاتف وكلمة المرور',
          ),
        ),
      );
      return;
    }

    if (_isSignUp) {
      if (fullName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال الاسم الكريم')),
        );
        return;
      }
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('كلمتا المرور غير متطابقتين!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    String emailOrPhone = input;
    if (RegExp(r'^07[0-9]{9}$').hasMatch(input)) {
      emailOrPhone = '$input@alaminstore.iq';
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await supabase.auth.signUp(
          email: emailOrPhone,
          password: password,
          data: {'full_name': fullName},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم إنشاء الحساب بنجاح!')),
          );
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: emailOrPhone,
          password: password,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(isGuest: false),
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

  void _showForgotPasswordDialog() {
    final resetInputCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة وتعديل كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل البريد الإلكتروني أو رقم الهاتف الذي سجلت به سابقاً:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetInputCtrl,
              decoration: const InputDecoration(
                labelText: 'البريد أو رقم الهاتف (07xxxxxxxxx)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              String val = resetInputCtrl.text.trim();
              if (val.isEmpty) return;
              if (RegExp(r'^07[0-9]{9}$').hasMatch(val)) {
                val = '$val@alaminstore.iq';
              }
              try {
                await supabase.auth.resetPasswordForEmail(val);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '✅ تم إرسال تعليمات ورابط تعديل كلمة المرور بنجاح',
                      ),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('إرسال رابط الاستعادة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'متجر الأمين',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront,
                        size: 50,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _isSignUp ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSignUp
                          ? 'أنشئ حسابك للاستمتاع بمزايا متجر الأمين'
                          : 'سجل برقم الهاتف أو البريد لتتبع طلباتك بسهولة',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (_isSignUp) ...[
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكريم *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        labelText: 'البريد أو رقم الهاتف (07xxxxxxxxx) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'تأكيد كلمة المرور *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                            : 'ليس لديك حساب؟ إنشاء حساب جديد',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    if (!_isSignUp)
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          'هل نسيت كلمة المرور؟ استعادة الرمز',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
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

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    unreadNotificationsCount.value = 0;
    try {
      html.window.localStorage['last_seen_notif'] = DateTime.now()
          .millisecondsSinceEpoch
          .toString();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إشعارات وتحديثات متجر الأمين')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد إشعارات حالياً',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSendNotificationScreen extends StatefulWidget {
  const AdminSendNotificationScreen({super.key});

  @override
  State<AdminSendNotificationScreen> createState() =>
      _AdminSendNotificationScreenState();
}

class _AdminSendNotificationScreenState
    extends State<AdminSendNotificationScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _isLoading = false;
  DateTime? _expiresAt;
  List<Map<String, dynamic>> _bannerRecords = [];

  @override
  void initState() {
    super.initState();
    _loadBannerRecordsForAdmin();
  }

  Future<void> _loadBannerRecordsForAdmin() async {
    final records = await _loadBannerRecords();
    if (mounted) setState(() => _bannerRecords = records);
  }

  Future<void> _sendNotification() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال عنوان ونَص الإشعار'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bannerMessage = '$title: $body';
      final wasSavedToServer = await _saveSharedBannerMessage(
        bannerMessage,
        expiresAt: _expiresAt,
      );
      if (!wasSavedToServer) {
        final banners = List<String>.from(bannerMessagesNotifier.value);
        banners.insert(0, bannerMessage);
        bannerMessagesNotifier.value = banners;
        _saveBannerMessagesToStorage(banners);
      } else {
        final banners = List<String>.from(bannerMessagesNotifier.value)
          ..insert(0, bannerMessage);
        bannerMessagesNotifier.value = banners;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasSavedToServer ? '✅ تم إرسال الخبر وظهر في البنر للجميع' : '⚠️ تم حفظ الخبر على هذا الجهاز فقط. شغّل ملف store_banners.sql في Supabase أولاً',
            ),
            backgroundColor: wasSavedToServer
                ? const Color(0xFF10B981)
                : Colors.orange.shade800,
          ),
        );
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _expiresAt = null;
        await _loadBannerRecordsForAdmin();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الإرسال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إرسال إشعار عام للزبائن')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'إرسال تنبيه أو خبر فوري يظهر للزبائن في المتجر:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإشعار *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'نص الرسالة / الخبر *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_rounded),
                label: Text(
                  _expiresAt == null
                      ? 'تحديد تاريخ انتهاء اختياري'
                      : 'ينتهي في: ${_expiresAt!.year}/${_expiresAt!.month}/${_expiresAt!.day}',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDate: _expiresAt ?? DateTime.now(),
                  );
                  if (picked != null) setState(() => _expiresAt = picked);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _sendNotification,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إرسال الإشعار الآن',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'إدارة الأخبار المنشورة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_bannerRecords.isEmpty)
                const Text('لا توجد أخبار محفوظة على الخادم حالياً'),
              ..._bannerRecords.map(
                (record) => Card(
                  child: ListTile(
                    title: Text(record['message']?.toString() ?? ''),
                    subtitle: Text(
                      record['expires_at'] == null
                          ? 'بدون تاريخ انتهاء'
                          : 'ينتهي: ${record['expires_at']}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'تعديل الخبر',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            final controller = TextEditingController(
                              text: record['message']?.toString() ?? '',
                            );
                            final updated = await showDialog<String>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('تعديل الخبر'),
                                content: TextField(
                                  controller: controller,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'نص الخبر',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('إلغاء'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(
                                      dialogContext,
                                      controller.text.trim(),
                                    ),
                                    child: const Text('حفظ'),
                                  ),
                                ],
                              ),
                            );
                            controller.dispose();
                            if (updated == null || updated.isEmpty) return;
                            try {
                              await supabase
                                  .from('store_banners')
                                  .update({'message': updated})
                                  .eq('id', record['id']);
                              await _loadBannerRecordsForAdmin();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تعذر تعديل الخبر: $e'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'حذف الخبر',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            try {
                              await supabase
                                  .from('store_banners')
                                  .delete()
                                  .eq('id', record['id']);
                              await _loadBannerRecordsForAdmin();
                              bannerMessagesNotifier.value = List<String>.from(
                                bannerMessagesNotifier.value,
                              )..remove(record['message'].toString());
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تعذر حذف الخبر: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrdersHistoryScreen extends StatefulWidget {
  final bool isGuest;
  const OrdersHistoryScreen({super.key, required this.isGuest});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  final TextEditingController _phoneCtrl = TextEditingController();
  List<Map<String, dynamic>> _myOrders = [];
  bool _searched = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchOrders() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 11 || !phone.startsWith('07')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إدخال رقم هاتف عراقي صحيح يتكون من 11 رقماً ويبدأ بـ 07',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _searched = true;
    });

    try {
      final res = await supabase
          .from('orders')
          .select()
          .eq('phone', phone)
          .order('id', ascending: false);

      if (mounted) {
        setState(() {
          _myOrders = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع طلباتي')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text(
                      'أدخل رقم هاتفك لتتبع حالة جميع طلباتك السابقة فوراً:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 11,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف (07xxxxxxxx)',
                              border: OutlineInputBorder(),
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isLoading ? null : _searchOrders,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'تتبع',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1E3A8A),
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text(
                        'سجل دخولك أو أنشئ حساباً لحفظ بياناتك ومتابعة طلباتك بسهولة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
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
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (!_searched
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'أدخل رقم الهاتف بالأعلى لعرض ومتابعة حالة طلباتك',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : (_myOrders.isEmpty
                              ? const Center(
                                  child: Text(
                                    'لا توجد طلبات مسجلة بهذا الرقم حالياً',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _myOrders.length,
                                  itemBuilder: (context, index) {
                                    final o = _myOrders[index];
                                    final status =
                                        o['status'] ?? 'قيد المراجعة';
                                    const stages = [
                                      'قيد المراجعة',
                                      'قيد التجهيز',
                                      'قيد التوصيل',
                                      'تم التوصيل',
                                    ];
                                    final currentStage = stages.indexOf(status);
                                    final stageIndex = currentStage < 0
                                        ? 0
                                        : currentStage;
                                    return Card(
                                      elevation: 1,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    o['product_name'] ?? 'طلب',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Chip(
                                                  label: Text(
                                                    status,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      status == 'تم التوصيل'
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFF1E3A8A),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'المبلغ: ${o['price']} د.ع\nالعنوان: ${o['address']}',
                                            ),
                                            const SizedBox(height: 14),
                                            Row(
                                              children: List.generate(
                                                stages.length,
                                                (stage) => Expanded(
                                                  child: Column(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 12,
                                                        backgroundColor:
                                                            stage <= stageIndex
                                                            ? const Color(
                                                                0xFF10B981,
                                                              )
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                        child: Icon(
                                                          stage <= stageIndex
                                                              ? Icons.check
                                                              : Icons.circle,
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        stages[stage],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ))),
            ),
          ],
        ),
      ),
    );
  }
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قائمة المفضلة ❤️')),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: wishlistNotifier,
        builder: (context, wishlist, _) {
          if (wishlist.isEmpty) {
            return const Center(
              child: Text(
                'قائمة المفضلة فارغة حالياً',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: wishlist.length,
            itemBuilder: (_, i) {
              final item = wishlist[i];
              return Card(
                child: ListTile(
                  leading: Image.network(
                    item['image'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image),
                  ),
                  title: Text(
                    item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${item['price']} د.ع',
                    style: const TextStyle(color: Color(0xFF10B981)),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      final updated = List<Map<String, dynamic>>.from(wishlist);
                      updated.removeAt(i);
                      wishlistNotifier.value = updated;
                      _saveWishlistToStorage(updated);
                    },
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

class AccountTabScreen extends StatelessWidget {
  final bool isGuest;
  final bool isAdmin;

  const AccountTabScreen({
    super.key,
    required this.isGuest,
    required this.isAdmin,
  });

  void _signOut(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthLandingScreen()),
      );
    }
  }

  void _openWhatsApp(String text) {
    final msg = Uri.encodeComponent(text);
    html.window.open('https://wa.me/$kWhatsAppNumber?text=$msg', '_blank');
  }

  void _showAppSupportDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Row(
            children: [
              Icon(Icons.support_agent, color: Color(0xFF1E3A8A)),
              SizedBox(width: 8),
              Text(
                'صندوق رسائل واستفسارات الزبائن',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكريم *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: msgCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'نص الرسالة / المشكلة *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              onPressed: isSending
                  ? null
                  : () async {
                      final n = nameCtrl.text.trim();
                      final p = phoneCtrl.text.trim();
                      final m = msgCtrl.text.trim();

                      if (n.isEmpty || p.isEmpty || m.isEmpty) return;

                      setDlgState(() => isSending = true);
                      try {
                        await supabase.from('orders').insert({
                          'product_name': 'استفسار دعم فني',
                          'price': 0,
                          'total_amount': 0,
                          'customer_name': n,
                          'phone': p,
                          'province': 'الدعم الفني',
                          'address': m,
                          'status': 'رسالة دعم واردة',
                        });

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '✅ تم إرسال رسالتك لإدارة المتجر بنجاح!',
                              ),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (_) {
                        setDlgState(() => isSending = false);
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'إرسال الرسالة',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'حسابي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث محلي',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 تم التحديث بنجاح'),
                  duration: Duration(milliseconds: 500),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: isAdmin
                            ? Colors.amber.shade100
                            : const Color(0xFF1E3A8A).withAlpha(20),
                        child: Icon(
                          isAdmin
                              ? Icons.admin_panel_settings
                              : (isGuest ? Icons.person_outline : Icons.person),
                          size: 32,
                          color: isAdmin
                              ? Colors.amber.shade900
                              : const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAdmin
                                  ? 'إدارة متجر الأمين'
                                  : (isGuest ? 'ضيف' : 'عميل متجر الأمين'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isGuest
                                  ? 'تستطيع تصفح المتجر والطلب بكل حرية'
                                  : (supabase.auth.currentUser?.email ?? ''),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF1E3A8A),
                      ),
                      title: const Text(
                        'تتبع طلباتي',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'تابع مراحل طلباتك باستخدام رقم الهاتف',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrdersHistoryScreen(isGuest: isGuest),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.red),
                      title: const Text(
                        'قائمة المفضلة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('المنتجات التي قمت بحفظها'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WishlistScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.support_agent,
                        color: Color(0xFF1E3A8A),
                      ),
                      title: const Text(
                        'صندوق رسائل واستفسارات الزبائن',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'إرسال استفسار مباشر للإدارة داخل التطبيق',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showAppSupportDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                      title: const Text(
                        'مراسلة الدعم عبر الواتساب',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('محادثة مباشرة مع خدمة العملاء'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _openWhatsApp(
                        'السلام عليكم متجر الأمين، لدي استفسار.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: Text(
                    isGuest
                        ? 'تسجيل الدخول / إنشاء حساب لحفظ بياناتك'
                        : 'تسجيل الخروج من الحساب',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    if (!isGuest) {
                      _signOut(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthLandingScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),
              if (!isGuest) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'تسجيل الخروج النهائي',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () => _signOut(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
  String? _selectedCategoryForProducts;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    if (currentIndex == 1) {
      _selectedCategoryForProducts =
          html.window.localStorage['selected_category'];
    }
    _initRealtimeListeners();
    selectedProductNotifier.addListener(_onSelectedProductChanged);
  }

  @override
  void dispose() {
    selectedProductNotifier.removeListener(_onSelectedProductChanged);
    super.dispose();
  }

  void _onSelectedProductChanged() {
    setState(() {});
  }

  void _initRealtimeListeners() {
    try {
      supabase
          .channel('public:orders_messages')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              final newRow = payload.newRecord;
              if (newRow['status'] == 'رسالة دعم واردة') {
                unreadAdminMessagesCount.value++;
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  void switchTab(int index) {
    setState(() {
      selectedProductNotifier.value = null;
      _selectedCategoryForProducts = null;
      currentIndex = index;
    });
    html.window.localStorage['current_tab'] = '$index';
    html.window.localStorage.remove('selected_category');
  }

  void openProductDetails(
    Map<String, dynamic> product,
    bool isAdmin,
    bool isGuest,
    VoidCallback onUpdated,
  ) {
    setState(() {
      selectedProductNotifier.value = product;
    });
  }

  void openCategoryProducts(String categoryName, bool isGuest) {
    setState(() {
      _selectedCategoryForProducts = categoryName;
    });
    html.window.localStorage['selected_category'] = categoryName;
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final bool currentIsGuest = user == null;
    final bool isAdmin = !currentIsGuest && user.email == kAdminEmail;

    Widget currentBody;
    if (selectedProductNotifier.value != null) {
      currentBody = ProductDetailsScreen(
        product: selectedProductNotifier.value!,
        isGuest: currentIsGuest,
        isAdmin: isAdmin,
        onProductUpdated: () => setState(() {}),
      );
    } else {
      final List<Widget> screens = [
        HomeScreen(
          isAdmin: isAdmin,
          isGuest: currentIsGuest,
          onSelectProduct: (item) =>
              openProductDetails(item, isAdmin, currentIsGuest, () {}),
        ),
        _selectedCategoryForProducts != null
            ? CategoryProductsScreenView(
                categoryName: _selectedCategoryForProducts!,
                isGuest: currentIsGuest,
                onBack: () {
                  setState(() => _selectedCategoryForProducts = null);
                  html.window.localStorage.remove('selected_category');
                },
              )
            : CategoriesScreen(
                isGuest: currentIsGuest,
                onSelectCategory: (cat) =>
                    openCategoryProducts(cat, currentIsGuest),
              ),
        const CartScreen(),
        isAdmin
            ? const AdminDashboardScreen()
            : AccountTabScreen(isGuest: currentIsGuest, isAdmin: isAdmin),
      ];
      currentBody = IndexedStack(index: currentIndex, children: screens);
    }

    return Scaffold(
      body: currentBody,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex > 3 ? 3 : currentIndex,
        onTap: switchTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        elevation: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_rounded),
            label: 'الرئيسية',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'الفئات',
          ),
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: cartNotifier,
              builder: (_, cart, _) => Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text(
                  '${cart.fold(0, (sum, item) => sum + (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1))}',
                ),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            label: 'السلة',
          ),
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<int>(
              valueListenable: unreadAdminMessagesCount,
              builder: (_, adminMsgs, __) => Badge(
                isLabelVisible: isAdmin && adminMsgs > 0,
                label: Text('$adminMsgs'),
                child: Icon(
                  isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.person_outline_rounded,
                ),
              ),
            ),
            label: isAdmin ? 'لوحة الإدارة' : 'حسابي',
          ),
        ],
      ),
    );
  }
}

// كلاس البنر المتحرك (Slider) التلقائي
class StoreBannerSlider extends StatefulWidget {
  const StoreBannerSlider({super.key});

  @override
  State<StoreBannerSlider> createState() => _StoreBannerSliderState();
}

class _StoreBannerSliderState extends State<StoreBannerSlider> {
  int _currentPage = 0;
  Timer? _timer;
  bool _isInteracting = false;

  List<String> _bannerMessages = [
    '🚚 توصيل فائق السرعة لكافة محافظات العراق والدفع عند الاستلام',
    '🔥 خصومات كبرى على كافة المنتجات الأصلية لفترة محدودة',
    '⭐ تسوق الآن واكتشف أحدث المنتجات بقسم العروض والتخفيضات',
    '🎁 عروض خاصة وأسعار مميزة يومياً في متجر الأمين',
    '🛍️ اطلب الآن والدفع عند الاستلام أينما كنت في العراق',
    '📦 منتجات جديدة تصل باستمرار، تابع آخر أخبار المتجر',
  ];

  @override
  void initState() {
    super.initState();
    _loadBanners();
    bannerMessagesNotifier.addListener(_onBannerMessagesChanged);
    _startAutoSlide();
  }

  void _onBannerMessagesChanged() {
    if (!mounted) return;
    setState(() {
      _bannerMessages = [
        ...bannerMessagesNotifier.value,
        ..._bannerMessages.take(6),
      ].toSet().toList();
    });
  }

  void _loadBanners() {
    _loadSharedBannerMessages().then((sharedMessages) {
      if (!mounted) return;
      final saved = sharedMessages.isNotEmpty
          ? sharedMessages
          : bannerMessagesNotifier.value;
      if (saved.isNotEmpty) {
        setState(() {
          _bannerMessages = [...saved, ..._bannerMessages].toSet().toList();
        });
      }
    });
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_isInteracting) return;
      if (_bannerMessages.isEmpty) return;
      setState(() {
        _currentPage = (_currentPage + 1) % _bannerMessages.length;
      });
    });
  }

  void _goToPage(int page) {
    if (_bannerMessages.isEmpty) return;
    setState(() {
      _currentPage = (page + _bannerMessages.length) % _bannerMessages.length;
    });
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    bannerMessagesNotifier.removeListener(_onBannerMessagesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF2196F3), Color(0xFF64B5F6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.amberAccent,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 700),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: Text(
                              _bannerMessages.isEmpty
                                  ? 'أهلاً بكم في متجر الأمين'
                                  : _bannerMessages[_currentPage],
                              key: ValueKey(
                                _bannerMessages.isEmpty
                                    ? 'empty'
                                    : _bannerMessages[_currentPage],
                              ),
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: Colors.amberAccent,
                      ),
                      onPressed: () => _goToPage(_currentPage - 1),
                      child: const Text(
                        '‹',
                        style: TextStyle(
                          fontSize: 32,
                          height: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 2,
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: Colors.amberAccent,
                      ),
                      onPressed: () => _goToPage(_currentPage + 1),
                      child: const Text(
                        '›',
                        style: TextStyle(
                          fontSize: 32,
                          height: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bannerMessages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 16 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.amberAccent
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isAdmin;
  final bool isGuest;
  final Function(Map<String, dynamic>) onSelectProduct;

  const HomeScreen({
    super.key,
    required this.isAdmin,
    required this.isGuest,
    required this.onSelectProduct,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _checkAbandonedCart();
  }

  void _checkAbandonedCart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (cartNotifier.value.isNotEmpty) {
        final lastVisited = html.window.localStorage['last_visited_time'];
        final now = DateTime.now().millisecondsSinceEpoch.toString();
        if (lastVisited != null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.shopping_cart_checkout,
                    color: Color(0xFF10B981),
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text('🛒 منتجات بانتظارك!'),
                ],
              ),
              content: const Text(
                'لديك منتجات مضافة مسبقاً في سلة التسوق الخاصة بك. هل ترغب في إكمال طلبك الآن؟',
                style: TextStyle(height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'لاحقاً',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    navKey.currentState?.switchTab(2);
                  },
                  child: const Text('الانتقال للسلة وإتمام الطلب'),
                ),
              ],
            ),
          );
        }
        html.window.localStorage['last_visited_time'] = now;
      }
    });
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

  void _showDirectOrderDialogFromHome(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final title = item['name'] ?? item['title'] ?? 'منتج';
    final dynamic price = item['price'] ?? 0;
    final colors = item['colors'] != null && item['colors'] is List
        ? item['colors']
        : [];
    final String? chosenColor = colors.isNotEmpty
        ? colors.first.toString()
        : null;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final couponCtrl = TextEditingController();
    String prov = 'بغداد';
    bool isSubmitting = false;
    double discountPercent = 0.0;
    String? appliedCoupon;

    final double itemPrice = double.tryParse(price.toString()) ?? 0;

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          double discountAmount = itemPrice * discountPercent;
          double totalWithDelivery =
              (itemPrice - discountAmount) + kDeliveryFee;

          return Padding(
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
                    'طلب: $title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (chosenColor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'اللون: $chosenColor',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('سعر المنتج:'),
                            Text(
                              '$itemPrice د.ع',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (discountPercent > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('قيمة الخصم:'),
                              Text(
                                '-$discountAmount د.ع',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('كلفة التوصيل (ثابت لكل العراق):'),
                            Text(
                              '5,000 د.ع',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
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
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: couponCtrl,
                          decoration: const InputDecoration(
                            labelText: 'كود التخفيض (مثل AMIN10)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final c = couponCtrl.text.trim().toUpperCase();
                          setModalState(() {
                            if (c == 'AMIN10') {
                              discountPercent = 0.10;
                              appliedCoupon = 'AMIN10 (خصم 10%)';
                            } else if (c == 'AMIN20') {
                              discountPercent = 0.20;
                              appliedCoupon = 'AMIN20 (خصم 20%)';
                            } else {
                              discountPercent = 0.0;
                              appliedCoupon = null;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ الكود غير صحيح'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          });
                        },
                        child: const Text('تطبيق'),
                      ),
                    ],
                  ),
                  if (appliedCoupon != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        'تم تطبيق: $appliedCoupon',
                        style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
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
                    initialValue: prov,
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
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final cName = nameCtrl.text.trim();
                              final cPhone = phoneCtrl.text.trim();
                              final cAddr = addrCtrl.text.trim();

                              if (cName.isEmpty || cAddr.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'يرجى إدخال الاسم والعنوان التفصيلي قبل إرسال الطلب',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (cPhone.length != 11 ||
                                  !cPhone.startsWith('07')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'يرجى إدخال رقم هاتف عراقي صحيح يتكون من 11 رقماً ويبدأ بـ 07',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                final finalProdName = chosenColor != null
                                    ? '$title (اللون: $chosenColor)'
                                    : title;

                                await supabase.from('orders').insert({
                                  'product_name': finalProdName,
                                  'price': totalWithDelivery,
                                  'total_amount': totalWithDelivery,
                                  'customer_name': cName,
                                  'phone': cPhone,
                                  'province': prov,
                                  'address': cAddr,
                                  'status': 'قيد المراجعة',
                                });

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  _showOrderSuccessDialog(
                                    context,
                                    title,
                                    totalWithDelivery,
                                    cName,
                                    cPhone,
                                    prov,
                                    cAddr,
                                    chosenColor ?? '',
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('خطأ في إرسال الطلب: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'إتمام الطلب',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4B942),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 22,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'متجر الأمين',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: unreadNotificationsCount,
            builder: (context, unreadCount, _) => IconButton(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.amberAccent,
                ),
              ),
              tooltip: 'الإشعارات والتحديثات',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: cartNotifier,
            builder: (context, cart, _) => IconButton(
              icon: Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text(
                  '${cart.fold(0, (sum, item) => sum + (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1))}',
                ),
                child: const Icon(Icons.shopping_cart_rounded, size: 24),
              ),
              onPressed: () => navKey.currentState?.switchTab(2),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث محلي',
            onPressed: () {
              _loadProducts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 تم تحديث قائمة المنتجات'),
                  duration: Duration(milliseconds: 600),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const StoreBannerSlider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج أو ماركة...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF1976D2),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE4E9EE)),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('خطأ في الاتصال: ${snapshot.error}'),
                  );
                }

                final allProducts = snapshot.data ?? [];
                final products = allProducts.where((p) {
                  if (p['is_deleted'] == true ||
                      p['status'] == 'مُحذف (سلة المحذوفات)')
                    return false;
                  if (_searchQuery.isEmpty) return true;
                  final title = (p['name'] ?? p['title'] ?? '')
                      .toString()
                      .toLowerCase();
                  final desc = (p['description'] ?? '')
                      .toString()
                      .toLowerCase();
                  return title.contains(_searchQuery.toLowerCase()) ||
                      desc.contains(_searchQuery.toLowerCase());
                }).toList();

                if (products.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'لا توجد منتجات منشورة حالياً'
                          : 'لا توجد نتائج مطابقة لـ ("$_searchQuery")',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int cols = constraints.maxWidth > 1100
                        ? 4
                        : (constraints.maxWidth > 750 ? 3 : 2);

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: constraints.maxWidth > 750
                            ? 0.72
                            : 0.59,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final item = products[index];
                        final String mainImg =
                            (item['image_url'] ?? item['image'] ?? '')
                                .toString()
                                .trim();
                        final String title =
                            item['name'] ?? item['title'] ?? 'منتج';
                        final dynamic price = item['price'] ?? 0;
                        final bool isOutOfStock =
                            item['out_of_stock'] == true ||
                            item['is_out_of_stock'] == true;
                        final int stockCount =
                            int.tryParse(
                              item['stock']?.toString() ??
                                  item['quantity']?.toString() ??
                                  '',
                            ) ??
                            0;
                        final colors =
                            item['colors'] != null && item['colors'] is List
                            ? item['colors']
                            : [];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE9EEF2)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF12304A).withAlpha(12),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () => widget.onSelectProduct(item),
                                      child: Container(
                                        width: double.infinity,
                                        color: Colors.grey.shade50,
                                        child: mainImg.isNotEmpty
                                            ? Image.network(
                                                mainImg,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder: (_, __, ___) =>
                                                    Center(
                                                      child: Icon(
                                                        Icons.image_outlined,
                                                        size: 40,
                                                        color: Colors
                                                            .grey
                                                            .shade400,
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
                                    if (isOutOfStock)
                                      Container(
                                        color: Colors.black54,
                                        child: const Center(
                                          child: Chip(
                                            backgroundColor: Colors.red,
                                            label: Text(
                                              'نفاد الكمية',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child:
                                          ValueListenableBuilder<
                                            List<Map<String, dynamic>>
                                          >(
                                            valueListenable: wishlistNotifier,
                                            builder: (context, wishlist, _) {
                                              final bool isFav = wishlist.any(
                                                (e) => e['name'] == title,
                                              );
                                              return CircleAvatar(
                                                backgroundColor: Colors.white
                                                    .withAlpha(220),
                                                radius: 18,
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: Icon(
                                                    isFav
                                                        ? Icons.favorite_rounded
                                                        : Icons
                                                              .favorite_border_rounded,
                                                    color: Colors.red,
                                                    size: 18,
                                                  ),
                                                  onPressed: () {
                                                    final currentList =
                                                        List<
                                                          Map<String, dynamic>
                                                        >.from(wishlist);
                                                    if (isFav) {
                                                      currentList.removeWhere(
                                                        (e) =>
                                                            e['name'] == title,
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            '💔 تمت الإزالة من المفضلة',
                                                          ),
                                                          duration: Duration(
                                                            milliseconds: 600,
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      currentList.add({
                                                        'name': title,
                                                        'price': price,
                                                        'image': mainImg,
                                                      });
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            '❤️ تمت الإضافة للمفضلة',
                                                          ),
                                                          duration: Duration(
                                                            milliseconds: 600,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    wishlistNotifier.value =
                                                        currentList;
                                                    _saveWishlistToStorage(
                                                      currentList,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                    ),
                                    if (widget.isAdmin)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Row(
                                          children: [
                                            Material(
                                              color: const Color(0xFF1E3A8A),
                                              shape: const CircleBorder(),
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.edit_rounded,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                tooltip: 'تعديل',
                                                onPressed: () async {
                                                  final res =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              EditProductScreen(
                                                                product: item,
                                                              ),
                                                        ),
                                                      );
                                                  if (res == true)
                                                    _loadProducts();
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Material(
                                              color: Colors.orange.shade800,
                                              shape: const CircleBorder(),
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.delete_rounded,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                tooltip: 'نقل للمحذوفات',
                                                onPressed: () async {
                                                  try {
                                                    await supabase
                                                        .from('products')
                                                        .update({
                                                          'is_deleted': true,
                                                        })
                                                        .eq('id', item['id']);
                                                    setState(() {});
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            '🗑️ تم نقل المنتج إلى سلة المحذوفات',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  } catch (_) {}
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => widget.onSelectProduct(item),
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$price د.ع',
                                      style: const TextStyle(
                                        color: Color(0xFF1976D2),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isOutOfStock
                                          ? 'نفد من المخزون'
                                          : stockCount > 0
                                          ? 'باقي $stockCount قطعة'
                                          : 'متوفر',
                                      style: TextStyle(
                                        color: isOutOfStock
                                            ? Colors.red
                                            : Colors.grey.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 38,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF1976D2,
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0xFF1976D2),
                                                  width: 1.5,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              onPressed: isOutOfStock
                                                  ? null
                                                  : () {
                                                      final currentList =
                                                          List<
                                                            Map<String, dynamic>
                                                          >.from(
                                                            cartNotifier.value,
                                                          );
                                                      final chosenColor =
                                                          colors.isNotEmpty
                                                          ? colors.first
                                                                .toString()
                                                          : '';
                                                      final existingIndex =
                                                          currentList.indexWhere(
                                                            (element) =>
                                                                element['name'] ==
                                                                    title &&
                                                                element['color'] ==
                                                                    chosenColor,
                                                          );

                                                      if (existingIndex >= 0) {
                                                        int qty =
                                                            int.tryParse(
                                                              currentList[existingIndex]['quantity']
                                                                      ?.toString() ??
                                                                  '1',
                                                            ) ??
                                                            1;
                                                        currentList[existingIndex]['quantity'] =
                                                            qty + 1;
                                                      } else {
                                                        currentList.add({
                                                          'name': title,
                                                          'price': price,
                                                          'image': mainImg,
                                                          'color': chosenColor,
                                                          'quantity': 1,
                                                        });
                                                      }
                                                      cartNotifier.value =
                                                          currentList;
                                                      _saveCartToStorage(
                                                        currentList,
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '✅ تمت إضافة ($title) للسلة',
                                                          ),
                                                          backgroundColor:
                                                              const Color(
                                                                0xFF1976D2,
                                                              ),
                                                          duration:
                                                              const Duration(
                                                                seconds: 1,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                              child: const Text(
                                                'أضف للسلة',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SizedBox(
                                            height: 38,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isOutOfStock
                                                    ? Colors.grey
                                                    : const Color(0xFF1976D2),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              onPressed: isOutOfStock
                                                  ? null
                                                  : () =>
                                                        _showDirectOrderDialogFromHome(
                                                          context,
                                                          item,
                                                        ),
                                              child: Text(
                                                isOutOfStock
                                                    ? 'نفدت'
                                                    : 'اطلب الآن',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
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
          ),
        ],
      ),
    );
  }
}

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isGuest;
  final bool isAdmin;
  final VoidCallback onProductUpdated;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.isGuest,
    required this.isAdmin,
    required this.onProductUpdated,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final PageController _pageController;
  int _currIndex = 0;
  String? _selectedColor;
  double _userRating = 5.0;
  final TextEditingController _commentCtrl = TextEditingController();
  final TextEditingController _reviewerNameCtrl = TextEditingController();
  List<Map<String, dynamic>> _localReviews = [];
  Uint8List? _reviewImageBytes;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadLocalReviews();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentCtrl.dispose();
    _reviewerNameCtrl.dispose();
    super.dispose();
  }

  void _loadLocalReviews() {
    try {
      final title = widget.product['name'] ?? widget.product['title'] ?? '';
      final raw = html.window.localStorage['reviews_$title'];
      if (raw != null && raw.isNotEmpty) {
        _localReviews = List<Map<String, dynamic>>.from(jsonDecode(raw));
      }
    } catch (_) {}
  }

  void _saveLocalReviews() {
    try {
      final title = widget.product['name'] ?? widget.product['title'] ?? '';
      html.window.localStorage['reviews_$title'] = jsonEncode(_localReviews);
    } catch (_) {}
  }

  void _pickReviewImage() {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(files[0]);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _reviewImageBytes = reader.result as Uint8List?;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📸 تم إرفاق الصورة بنجاح'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        });
      }
    });
  }

  List<String> _getAllImages() {
    List<String> imgs = [];
    final String mainImg =
        (widget.product['image_url'] ?? widget.product['image'] ?? '')
            .toString()
            .trim();
    if (mainImg.isNotEmpty) {
      imgs.add(mainImg);
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
      if (uri.pathSegments.contains('shorts') && uri.pathSegments.length > 1)
        return uri.pathSegments[1];
      if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty)
        return uri.pathSegments.first;
      if (uri.queryParameters.containsKey('v')) return uri.queryParameters['v'];
    } catch (_) {}
    return null;
  }

  void _openFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              maxScale: 5.0,
              child: Center(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(String productName) async {
    final comment = _commentCtrl.text.trim();
    final name = _reviewerNameCtrl.text.trim();
    if (comment.isEmpty) return;

    String base64Img = '';
    if (_reviewImageBytes != null) {
      base64Img = 'data:image/jpeg;base64,${base64Encode(_reviewImageBytes!)}';
    }

    final newReview = {
      'reviewer_name': name.isEmpty ? 'زبون زائر' : name,
      'rating': _userRating,
      'comment': comment,
      'image_bytes': base64Img,
    };

    setState(() {
      _localReviews.insert(0, newReview);
      _reviewImageBytes = null;
    });
    _saveLocalReviews();

    try {
      await supabase.from('product_reviews').insert({
        'product_name': productName,
        'reviewer_name': newReview['reviewer_name'],
        'rating': _userRating,
        'comment': comment,
      });
    } catch (_) {}

    _commentCtrl.clear();
    _reviewerNameCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال تقييمك وتعليقك بنجاح'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  void _shareProduct(String title, dynamic price) {
    final String currentUrl = html.window.location.href;
    final String msg = Uri.encodeComponent(
      'شاهد هذا المنتج الرائع في متجر الأمين:\n$title\nالسعر: $price د.ع\nالرابط: $currentUrl',
    );
    html.window.open('https://wa.me/?text=$msg', '_blank');
  }

  void _openWhatsApp(String title, dynamic price) {
    final String chosenCol = _selectedColor ?? '';
    String msgText =
        'السلام عليكم متجر الأمين،\nأود طلب المنتج التالي:\n- المنتج: $title\n';
    if (chosenCol.isNotEmpty) {
      msgText += '- اللون: $chosenCol\n';
    }
    msgText +=
        '- السعر: $price د.ع (+ 5,000 د.ع توصيل لكافة المحافظات)\nيرجى تثبيت الطلب.';
    final String msg = Uri.encodeComponent(msgText);
    html.window.open('https://wa.me/$kWhatsAppNumber?text=$msg', '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final imgs = _getAllImages();
    final title = widget.product['name'] ?? widget.product['title'] ?? '';
    final price = widget.product['price'] ?? 0;
    final desc = widget.product['description'] ?? '';
    final bool isOutOfStock =
        widget.product['out_of_stock'] == true ||
        widget.product['is_out_of_stock'] == true;
    final String videoRaw = widget.product['video_url'] ?? '';
    final String? youtubeVideoId = _extractYouTubeId(videoRaw);
    final colors =
        widget.product['colors'] != null && widget.product['colors'] is List
        ? List<dynamic>.from(widget.product['colors'])
        : [];

    if (_selectedColor == null && colors.isNotEmpty) {
      _selectedColor = colors.first.toString();
    }

    final int totalMediaCount = imgs.length + (youtubeVideoId != null ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            selectedProductNotifier.value = null;
          },
        ),
        actions: [
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: wishlistNotifier,
            builder: (context, wishlist, _) {
              final bool isFav = wishlist.any((e) => e['name'] == title);
              return IconButton(
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: Colors.red,
                ),
                tooltip: 'المفضلة',
                onPressed: () {
                  final currentList = List<Map<String, dynamic>>.from(wishlist);
                  if (isFav) {
                    currentList.removeWhere((e) => e['name'] == title);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('💔 تمت الإزالة من المفضلة'),
                        duration: Duration(milliseconds: 800),
                      ),
                    );
                  } else {
                    currentList.add({
                      'name': title,
                      'price': price,
                      'image': imgs.isNotEmpty ? imgs.first : '',
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❤️ تمت الإضافة للمفضلة بنجاح'),
                        duration: Duration(milliseconds: 800),
                      ),
                    );
                  }
                  wishlistNotifier.value = currentList;
                  _saveWishlistToStorage(currentList);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'مشاركة المنتج',
            onPressed: () => _shareProduct(title, price),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث محلي',
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 تم تحديث صفحة المنتج محلياً'),
                  duration: Duration(milliseconds: 600),
                ),
              );
            },
          ),
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProductScreen(product: widget.product),
                  ),
                );
                if (res == true) {
                  widget.onProductUpdated();
                  setState(() {});
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOutOfStock)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '⚠️ عذراً، هذا المنتج نفذت كميته مؤقتاً.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isDesktop = constraints.maxWidth > 750;

                    Widget mediaSection = Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 380,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: PageView(
                                  controller: _pageController,
                                  onPageChanged: (i) =>
                                      setState(() => _currIndex = i),
                                  children: [
                                    if (imgs.isNotEmpty)
                                      ...imgs.map(
                                        (url) => GestureDetector(
                                          onTap: () =>
                                              _openFullScreenImage(url),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.network(
                                                url,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 60,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                              ),
                                              Positioned(
                                                bottom: 12,
                                                left: 12,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Row(
                                                    children: [
                                                      Icon(
                                                        Icons.zoom_in,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'اضغط لتكبير الصورة',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (youtubeVideoId != null)
                                      WebVideoPlayer(videoId: youtubeVideoId),
                                  ],
                                ),
                              ),
                            ),
                            if (totalMediaCount > 1 && _currIndex > 0)
                              Positioned(
                                right: 12,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _pageController.previousPage(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            if (totalMediaCount > 1 &&
                                _currIndex < totalMediaCount - 1)
                              Positioned(
                                left: 12,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _pageController.nextPage(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  youtubeVideoId != null &&
                                          _currIndex == imgs.length
                                      ? '🎬 فيديو المنتج'
                                      : 'صورة ${_currIndex + 1} من ${imgs.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (totalMediaCount > 1)
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: totalMediaCount,
                              itemBuilder: (context, i) {
                                bool isVideoThumb =
                                    (youtubeVideoId != null &&
                                    i == imgs.length);
                                return GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(
                                      i,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 10),
                                    width: 70,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _currIndex == i
                                            ? const Color(0xFF1E3A8A)
                                            : Colors.grey.shade300,
                                        width: _currIndex == i ? 3 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      color: isVideoThumb
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: isVideoThumb
                                          ? const Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.play_circle_fill,
                                                  color: Colors.red,
                                                  size: 30,
                                                ),
                                                Text(
                                                  'فيديو',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Image.network(
                                              imgs[i],
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );

                    Widget detailsSection = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$price د.ع',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (colors.isNotEmpty) ...[
                          const Text(
                            'اختر اللون المطلوب:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: colors.map((col) {
                              final String colorStr = col.toString();
                              final bool isSelected =
                                  _selectedColor == colorStr;
                              return ChoiceChip(
                                label: Text(colorStr),
                                selected: isSelected,
                                onSelected: (val) {
                                  setState(() => _selectedColor = colorStr);
                                },
                                selectedColor: const Color(0xFF1E3A8A)
                                    .withAlpha(40),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E3A8A),
                                    side: const BorderSide(
                                      color: Color(0xFF1E3A8A),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.add_shopping_cart_rounded,
                                  ),
                                  label: const Text(
                                    'إضافة للسلة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  onPressed: isOutOfStock
                                      ? null
                                      : () {
                                          final currentList =
                                              List<Map<String, dynamic>>.from(
                                                cartNotifier.value,
                                              );
                                          final chosenColor = colors.isNotEmpty
                                              ? (_selectedColor ??
                                                    colors.first.toString())
                                              : '';
                                          final existingIndex = currentList
                                              .indexWhere(
                                                (element) =>
                                                    element['name'] == title &&
                                                    element['color'] ==
                                                        chosenColor,
                                              );

                                          if (existingIndex >= 0) {
                                            int qty =
                                                int.tryParse(
                                                  currentList[existingIndex]['quantity']
                                                          ?.toString() ??
                                                      '1',
                                                ) ??
                                                1;
                                            currentList[existingIndex]['quantity'] =
                                                qty + 1;
                                          } else {
                                            currentList.add({
                                              'name': title,
                                              'price': price,
                                              'image': imgs.isNotEmpty
                                                  ? imgs.first
                                                  : '',
                                              'color': chosenColor,
                                              'quantity': 1,
                                            });
                                          }
                                          cartNotifier.value = currentList;
                                          _saveCartToStorage(currentList);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '✅ تمت إضافة ($title) للسلة',
                                              ),
                                              backgroundColor: const Color(
                                                0xFF1976D2,
                                              ),
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
                                            ),
                                          );
                                        },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOutOfStock
                                        ? Colors.grey
                                        : const Color(0xFF1976D2),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.flash_on_rounded),
                                  label: Text(
                                    isOutOfStock ? 'نفدت الكمية' : 'اطلب الآن',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  onPressed: isOutOfStock
                                      ? null
                                      : () => _showDirectOrderDialog(
                                          context,
                                          title,
                                          price,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.chat_rounded),
                            label: const Text(
                              'أو اطلب عبر الواتساب مباشرة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            onPressed: () => _openWhatsApp(title, price),
                          ),
                        ),
                      ],
                    );

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: mediaSection),
                          const SizedBox(width: 24),
                          Expanded(flex: 5, child: detailsSection),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          mediaSection,
                          const SizedBox(height: 20),
                          detailsSection,
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 30),
                const Divider(height: 1),
                const SizedBox(height: 20),

                const Text(
                  'الوصف والمواصفات:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(height: 1),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'منتجات قد تعجبك أيضاً 🛍️',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1E3A8A),
                      ),
                      icon: const Icon(Icons.grid_view_rounded, size: 16),
                      label: const Text('تصفح كل الفئات'),
                      onPressed: () {
                        selectedProductNotifier.value = null;
                        navKey.currentState?.switchTab(1);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: supabase
                        .from('products')
                        .select()
                        .order('id', ascending: false)
                        .limit(8)
                        .then((data) => List<Map<String, dynamic>>.from(data)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final suggestedProducts = (snapshot.data ?? [])
                          .where((p) => (p['name'] ?? p['title']) != title)
                          .take(4)
                          .toList();
                      if (suggestedProducts.isEmpty) {
                        return const Text(
                          'لا توجد منتجات مقترحة حالياً',
                          style: TextStyle(color: Colors.grey),
                        );
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestedProducts.length,
                        itemBuilder: (context, index) {
                          final prod = suggestedProducts[index];
                          final prodName = prod['name'] ?? prod['title'] ?? '';
                          final prodPrice = prod['price'] ?? 0;
                          final prodImg =
                              prod['image_url'] ?? prod['image'] ?? '';

                          return Container(
                            width: 150,
                            margin: const EdgeInsets.only(left: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: InkWell(
                              onTap: () {
                                selectedProductNotifier.value = prod;
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: prodImg.isNotEmpty
                                          ? Image.network(
                                              prodImg,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.image),
                                            )
                                          : const Center(
                                              child: Icon(Icons.image),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prodName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$prodPrice د.ع',
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
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
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(height: 1),
                const SizedBox(height: 20),

                const Text(
                  'التعليقات والتقييمات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('قيم المنتج: '),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _userRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                          ),
                          onPressed: () => setState(
                            () => _userRating = (index + 1).toDouble(),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                TextField(
                  controller: _reviewerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسمك الكريم (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'اكتب رأيك أو تجربتك بالمنتج...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E3A8A),
                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('اختر صورة من الجهاز (اختياري)'),
                      onPressed: _pickReviewImage,
                    ),
                    if (_reviewImageBytes != null) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _reviewImageBytes!,
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            setState(() => _reviewImageBytes = null),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _submitReview(title),
                  child: const Text(
                    'إرسال',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                _localReviews.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _localReviews.length,
                        itemBuilder: (_, i) {
                          final r = _localReviews[i];
                          final String imgBytes =
                              r['image_bytes']?.toString() ?? '';
                          final int rRating =
                              int.tryParse(r['rating']?.toString() ?? '5') ?? 5;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        r['reviewer_name'] ?? 'زبون',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          rRating,
                                          (_) => const Icon(
                                            Icons.star,
                                            size: 14,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(r['comment'] ?? ''),
                                  if (imgBytes.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(imgBytes.split(',').last),
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : FutureBuilder<List<Map<String, dynamic>>>(
                        future: supabase
                            .from('product_reviews')
                            .select()
                            .eq('product_name', title)
                            .order('id', ascending: false),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final reviews = snapshot.data ?? [];
                          if (reviews.isEmpty) {
                            return const Text(
                              'لا توجد تعليقات أو تقييمات لهذا المنتج حتى الآن.',
                              style: TextStyle(color: Colors.grey),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reviews.length,
                            itemBuilder: (_, i) {
                              final r = reviews[i];
                              final int dbRating =
                                  int.tryParse(
                                    r['rating']?.toString() ?? '5',
                                  ) ??
                                  5;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        r['reviewer_name'] ?? 'زبون',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          dbRating,
                                          (_) => const Icon(
                                            Icons.star,
                                            size: 14,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(r['comment'] ?? ''),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
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
    final couponCtrl = TextEditingController();
    String prov = 'بغداد';
    bool isSubmitting = false;
    double discountPercent = 0.0;
    String? appliedCoupon;

    final double itemPrice = double.tryParse(productPrice.toString()) ?? 0;
    final colors =
        widget.product['colors'] != null && widget.product['colors'] is List
        ? widget.product['colors']
        : [];
    final String? chosenColor = colors.isNotEmpty
        ? (_selectedColor ?? colors.first.toString())
        : null;

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          double discountAmount = itemPrice * discountPercent;
          double totalWithDelivery =
              (itemPrice - discountAmount) + kDeliveryFee;

          return Padding(
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
                    'اتمام الطلب: $title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (chosenColor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'اللون: $chosenColor',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('سعر المنتج:'),
                            Text(
                              '$itemPrice د.ع',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (discountPercent > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('قيمة الخصم:'),
                              Text(
                                '-$discountAmount د.ع',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('كلفة التوصيل (ثابت لكل العراق):'),
                            Text(
                              '5,000 د.ع',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
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
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: couponCtrl,
                          decoration: const InputDecoration(
                            labelText: 'كود التخفيض (مثل AMIN10)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final c = couponCtrl.text.trim().toUpperCase();
                          setModalState(() {
                            if (c == 'AMIN10') {
                              discountPercent = 0.10;
                              appliedCoupon = 'AMIN10 (خصم 10%)';
                            } else if (c == 'AMIN20') {
                              discountPercent = 0.20;
                              appliedCoupon = 'AMIN20 (خصم 20%)';
                            } else {
                              discountPercent = 0.0;
                              appliedCoupon = null;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ الكود غير صحيح'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          });
                        },
                        child: const Text('تطبيق'),
                      ),
                    ],
                  ),
                  if (appliedCoupon != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        'تم تطبيق: $appliedCoupon',
                        style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
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
                    initialValue: prov,
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
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final cName = nameCtrl.text.trim();
                              final cPhone = phoneCtrl.text.trim();
                              final cAddr = addrCtrl.text.trim();

                              if (cName.isEmpty || cAddr.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'يرجى إدخال الاسم والعنوان التفصيلي قبل إرسال الطلب',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (cPhone.length != 11 ||
                                  !cPhone.startsWith('07')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'يرجى إدخال رقم هاتف عراقي صحيح يتكون من 11 رقماً ويبدأ بـ 07',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                final finalProdName = chosenColor != null
                                    ? '$title (اللون: $chosenColor)'
                                    : title;

                                await supabase.from('orders').insert({
                                  'product_name': finalProdName,
                                  'price': totalWithDelivery,
                                  'total_amount': totalWithDelivery,
                                  'customer_name': cName,
                                  'phone': cPhone,
                                  'province': prov,
                                  'address': cAddr,
                                  'status': 'قيد المراجعة',
                                });

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  _showOrderSuccessDialog(
                                    context,
                                    title,
                                    totalWithDelivery,
                                    cName,
                                    cPhone,
                                    prov,
                                    cAddr,
                                    chosenColor ?? '',
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('خطأ في إرسال الطلب: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'إتمام الطلب',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponCtrl = TextEditingController();
  double _discountPercent = 0.0;
  String? _appliedCouponName;

  void _applyCoupon() {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code == 'AMIN10') {
      setState(() {
        _discountPercent = 0.10;
        _appliedCouponName = 'AMIN10 (خصم 10%)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تطبيق الكوبون بنجاح'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else if (code == 'AMIN20') {
      setState(() {
        _discountPercent = 0.20;
        _appliedCouponName = 'AMIN20 (خصم 20%)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تطبيق الكوبون بنجاح'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ كود التخفيض غير صحيح'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareCart(List<Map<String, dynamic>> cartItems) {
    try {
      final jsonStr = jsonEncode(cartItems);
      final bytes = utf8.encode(jsonStr);
      final base64Str = base64Url.encode(bytes);

      final origin = html.window.location.origin ?? '';
      final pathname = html.window.location.pathname ?? '';
      final baseUri = origin + pathname;
      final sharedLink = '$baseUri?shared_cart=$base64Str';

      String msgText =
          '🛒 تسوق معي من متجر الأمين! هذه هي سلة منتجاتي المجهزة:\n';
      for (var itm in cartItems) {
        final iName = itm['name'] ?? 'منتج';
        final iQty = itm['quantity'] ?? 1;
        final iColor = itm['color']?.toString() ?? '';
        msgText += '- $iName (العدد: $iQty)';
        if (iColor.isNotEmpty) msgText += ' [اللون: $iColor]';
        msgText += '\n';
      }
      msgText += '\nرابط السلة المباشر:\n$sharedLink';

      final msg = Uri.encodeComponent(msgText);
      html.window.open('https://wa.me/?text=$msg', '_blank');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في مشاركة السلة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleCheckout(
    BuildContext context,
    double total,
    List<Map<String, dynamic>> items,
  ) {
    _showCheckoutDialog(context, total, items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('سلة التسوق'),
      ),
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
                    onPressed: () => navKey.currentState?.switchTab(0),
                    child: const Text('تصفح منتجات متجر الأمين'),
                  ),
                ],
              ),
            );
          }

          double subtotal = cart.fold(0.0, (sum, item) {
            double p = double.tryParse(item['price'].toString()) ?? 0;
            int q = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
            return sum + (p * q);
          });

          double discountAmount = subtotal * _discountPercent;
          double grandTotal = (subtotal - discountAmount) + kDeliveryFee;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(
                        color: Color(0xFF25D366),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text(
                      'مشاركة السلة عبر رابط الواتساب',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () => _shareCart(cart),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final item = cart[i];
                    final int qty =
                        int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                    final double itemPrice =
                        double.tryParse(item['price'].toString()) ?? 0.0;
                    final String itemColor = item['color']?.toString() ?? '';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            item['image'].toString().isNotEmpty
                                ? Image.network(
                                    item['image'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image, size: 60),
                                  )
                                : const Icon(Icons.image, size: 60),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    itemColor.isNotEmpty
                                        ? 'اللون: $itemColor | السعر: $itemPrice د.ع'
                                        : 'السعر: $itemPrice د.ع',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
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
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    final updated =
                                        List<Map<String, dynamic>>.from(cart);
                                    if (qty > 1) {
                                      updated[i]['quantity'] = qty - 1;
                                    } else {
                                      updated.removeAt(i);
                                    }
                                    cartNotifier.value = updated;
                                    _saveCartToStorage(updated);
                                  },
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFF10B981),
                                  ),
                                  onPressed: () {
                                    final updated =
                                        List<Map<String, dynamic>>.from(cart);
                                    updated[i]['quantity'] = qty + 1;
                                    cartNotifier.value = updated;
                                    _saveCartToStorage(updated);
                                  },
                                ),
                              ],
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
                                _saveCartToStorage(updated);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponCtrl,
                        decoration: const InputDecoration(
                          labelText: 'أدخل كود التخفيض (مثل AMIN10)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _applyCoupon,
                      child: const Text('تطبيق'),
                    ),
                  ],
                ),
              ),
              if (_appliedCouponName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'تم تطبيق الكوبون: $_appliedCouponName',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المجموع: $grandTotal د.ع',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          _handleCheckout(context, grandTotal, cart),
                      child: const Text('إتمام طلب السلة'),
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
          title: const Text('تأكيد بيانات التوصيل والدفع عند الاستلام'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المبلغ الكلي شامل التوصيل: $total د.ع',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
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
                  initialValue: prov,
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
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final customerName = name.text.trim();
                      final customerPhone = phone.text.trim();
                      final customerAddr = addr.text.trim();

                      if (customerName.isEmpty || customerAddr.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'يرجى إدخال الاسم والعنوان التفصيلي قبل إرسال الطلب',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (customerPhone.length != 11 ||
                          !customerPhone.startsWith('07')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'يرجى إدخال رقم هاتف عراقي صحيح يتكون من 11 رقماً ويبدأ بـ 07',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDlgState(() => isSubmitting = true);
                      try {
                        for (var itm in items) {
                          final itemPrice =
                              double.tryParse(itm['price'].toString()) ?? 0.0;
                          final int qty =
                              int.tryParse(
                                itm['quantity']?.toString() ?? '1',
                              ) ??
                              1;
                          final double itemTotal = itemPrice * qty;
                          final String iName = itm['name'] ?? 'منتج';
                          final String iColor = itm['color']?.toString() ?? '';

                          String formattedName = '$iName (العدد: $qty)';
                          if (iColor.isNotEmpty) {
                            formattedName += ' - اللون: $iColor';
                          }

                          await supabase.from('orders').insert({
                            'product_name': formattedName,
                            'price': itemTotal,
                            'total_amount': itemTotal,
                            'customer_name': customerName,
                            'phone': customerPhone,
                            'province': prov,
                            'address': customerAddr,
                            'status': 'قيد المراجعة',
                          });
                        }

                        cartNotifier.value = [];
                        _saveCartToStorage([]);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          navKey.currentState?.switchTab(0);
                          _showOrderSuccessDialog(
                            context,
                            'عدة منتجات من السلة',
                            total,
                            customerName,
                            customerPhone,
                            prov,
                            customerAddr,
                            '',
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('خطأ في إرسال السلة: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'إتمام الطلب',
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

class CategoriesScreen extends StatelessWidget {
  final bool isGuest;
  final Function(String) onSelectCategory;
  const CategoriesScreen({
    super.key,
    required this.isGuest,
    required this.onSelectCategory,
  });

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('فئات متجر الأمين'),
      ),
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
                onTap: () => onSelectCategory(catName),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E9EE)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF12304A).withAlpha(10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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

class CategoryProductsScreenView extends StatelessWidget {
  final String categoryName;
  final bool isGuest;
  final VoidCallback onBack;
  const CategoryProductsScreenView({
    super.key,
    required this.categoryName,
    required this.isGuest,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('products')
            .select()
            .order('id', ascending: false)
            .then((data) {
              final list = List<Map<String, dynamic>>.from(data);
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
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('لا توجد منتجات في قسم ($categoryName) حالياً'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onBack,
                    child: const Text('الرجوع للفئات'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final item = products[index];
              final String mainImg = (item['image_url'] ?? item['image'] ?? '')
                  .toString()
                  .trim();
              final String title = item['name'] ?? item['title'] ?? 'منتج';
              final dynamic price = item['price'] ?? 0;

              return Card(
                child: InkWell(
                  onTap: () {
                    selectedProductNotifier.value = item;
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: mainImg.isNotEmpty
                            ? Image.network(
                                mainImg,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              )
                            : const Center(child: Icon(Icons.image)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$price د.ع',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

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

  Future<void> _updateOrderStatus(
    dynamic orderId,
    String newStatus,
    String customerPhone,
    String productName,
  ) async {
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم تحديث حالة الطلب إلى ($newStatus)'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحديث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _softDeleteOrder(dynamic orderId) async {
    try {
      await supabase
          .from('orders')
          .update({'status': 'مُحذف (سلة المحذوفات)'})
          .eq('id', orderId);
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ تم نقل الطلب إلى سلة المحذوفات'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('إدارة الطلبات والمحذوفات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'سلة محذوفات الطلبات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminTrashOrdersScreen(),
                ),
              ).then((_) => _loadOrders());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: Text('خطأ في تحميل الطلبات: ${snapshot.error}'),
            );
          final all = snapshot.data ?? [];
          final orders = all
              .where(
                (o) =>
                    (o['status'] ?? '') != 'رسالة دعم واردة' &&
                    (o['status'] ?? '') != 'مُحذف (سلة المحذوفات)',
              )
              .toList();

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'لا توجد طلبات شراء نشطة حالياً',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminTrashOrdersScreen(),
                        ),
                      ).then((_) => _loadOrders());
                    },
                    icon: const Icon(Icons.restore_from_trash),
                    label: const Text('فتح سلة محذوفات الطلبات'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final o = orders[i];
              final dynamic orderId = o['id'];
              final String currentStatus = o['status'] ?? 'قيد المراجعة';
              final String customerPhone = o['phone'] ?? '';
              final String productName = o['product_name'] ?? 'طلب';
              const allowedStatuses = [
                'قيد المراجعة',
                'قيد التجهيز',
                'قيد التوصيل',
                'تم التوصيل',
                'إلغاء',
              ];
              final dropdownValue = allowedStatuses.contains(currentStatus)
                  ? currentStatus
                  : 'قيد المراجعة';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'نقل إلى سلة المحذوفات',
                            onPressed: () => _softDeleteOrder(orderId),
                          ),
                        ],
                      ),
                      Text(
                        'المبلغ الشامل: ${o['price']} د.ع',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'الزبون: ${o['customer_name']} | الهاتف: $customerPhone',
                      ),
                      Text('العنوان: ${o['address']}'),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'الحالة: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Chip(
                                label: Text(
                                  currentStatus,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: currentStatus == 'تم التوصيل'
                                    ? const Color(0xFF10B981)
                                    : (currentStatus == 'إلغاء'
                                          ? Colors.red
                                          : const Color(0xFF1E3A8A)),
                              ),
                            ],
                          ),
                          DropdownButton<String>(
                            value: dropdownValue,
                            items: allowedStatuses
                                .map(
                                  (st) => DropdownMenuItem(
                                    value: st,
                                    child: Text(st),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null)
                                _updateOrderStatus(
                                  orderId,
                                  val,
                                  customerPhone,
                                  productName,
                                );
                            },
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
    );
  }
}

class AdminTrashOrdersScreen extends StatefulWidget {
  const AdminTrashOrdersScreen({super.key});

  @override
  State<AdminTrashOrdersScreen> createState() => _AdminTrashOrdersScreenState();
}

class _AdminTrashOrdersScreenState extends State<AdminTrashOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _trashFuture;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  void _loadTrash() {
    setState(() {
      _trashFuture = supabase
          .from('orders')
          .select()
          .eq('status', 'مُحذف (سلة المحذوفات)')
          .order('id', ascending: false)
          .then((d) => List<Map<String, dynamic>>.from(d));
    });
  }

  Future<void> _restoreOrder(dynamic id) async {
    await supabase
        .from('orders')
        .update({'status': 'قيد المراجعة'})
        .eq('id', id);
    _loadTrash();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم استعادة الطلب بنجاح'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _permanentDeleteOrder(dynamic id) async {
    try {
      await supabase.from('orders').delete().eq('id', id);
      _loadTrash();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ تم حذف الطلب نهائياً'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف النهائي: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة محذوفات الطلبات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _trashFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final items = snapshot.data ?? [];
          if (items.isEmpty)
            return const Center(child: Text('سلة محذوفات الطلبات فارغة'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final o = items[i];
              return Card(
                child: ListTile(
                  title: Text(o['product_name'] ?? 'طلب'),
                  subtitle: Text(
                    'الزبون: ${o['customer_name']} | المبلغ: ${o['price']} د.ع',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.restore,
                          color: Color(0xFF10B981),
                        ),
                        tooltip: 'استعادة',
                        onPressed: () => _restoreOrder(o['id']),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        tooltip: 'حذف نهائي',
                        onPressed: () => _permanentDeleteOrder(o['id']),
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

class AdminTrashProductsScreen extends StatefulWidget {
  const AdminTrashProductsScreen({super.key});

  @override
  State<AdminTrashProductsScreen> createState() =>
      _AdminTrashProductsScreenState();
}

class _AdminTrashProductsScreenState extends State<AdminTrashProductsScreen> {
  late Future<List<Map<String, dynamic>>> _trashFuture;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  void _loadTrash() {
    setState(() {
      _trashFuture = supabase
          .from('products')
          .select()
          .eq('is_deleted', true)
          .order('id', ascending: false)
          .then((d) => List<Map<String, dynamic>>.from(d));
    });
  }

  Future<void> _restoreProduct(dynamic id) async {
    await supabase.from('products').update({'is_deleted': false}).eq('id', id);
    _loadTrash();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم استعادة المنتج بنجاح للمتجر'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _permanentDeleteProduct(dynamic id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
      _loadTrash();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ تم حذف المنتج نهائياً'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف النهائي: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة محذوفات المنتجات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _trashFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final items = snapshot.data ?? [];
          if (items.isEmpty)
            return const Center(child: Text('سلة محذوفات المنتجات فارغة'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final p = items[i];
              return Card(
                child: ListTile(
                  leading:
                      p['image_url'] != null &&
                          p['image_url'].toString().isNotEmpty
                      ? Image.network(
                          p['image_url'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image),
                        )
                      : const Icon(Icons.image, size: 50),
                  title: Text(
                    p['name'] ?? 'منتج',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${p['price']} د.ع'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.restore,
                          color: Color(0xFF10B981),
                        ),
                        tooltip: 'استعادة للمتجر',
                        onPressed: () => _restoreProduct(p['id']),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        tooltip: 'حذف نهائي',
                        onPressed: () => _permanentDeleteProduct(p['id']),
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

class AdminSupportMessagesScreen extends StatefulWidget {
  const AdminSupportMessagesScreen({super.key});

  @override
  State<AdminSupportMessagesScreen> createState() =>
      _AdminSupportMessagesScreenState();
}

class _AdminSupportMessagesScreenState
    extends State<AdminSupportMessagesScreen> {
  late Future<List<Map<String, dynamic>>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    unreadAdminMessagesCount.value = 0;
  }

  void _loadMessages() {
    setState(() {
      _messagesFuture = supabase
          .from('orders')
          .select()
          .eq('status', 'رسالة دعم واردة')
          .order('id', ascending: false)
          .then((d) => List<Map<String, dynamic>>.from(d));
    });
  }

  Future<void> _deleteMessage(dynamic msgId) async {
    try {
      await supabase.from('orders').delete().eq('id', msgId);
      _loadMessages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حذف الرسالة بنجاح'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReplyDialog(
    BuildContext context,
    String customerName,
    String customerPhone,
  ) {
    final replyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('الرد على الزبون: $customerName'),
        content: TextField(
          controller: replyCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'اكتب رد الإدارة هنا...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ تم إرسال الرد للزبون بنجاح!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('إرسال الرد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صندوق رسائل واستفسارات الزبائن'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final msgs = snapshot.data ?? [];
          if (msgs.isEmpty)
            return const Center(child: Text('لا توجد رسائل دعم واردة حالياً'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final m = msgs[i];
              final dynamic msgId = m['id'];
              final phone = m['phone']?.toString() ?? '';
              final name = m['customer_name']?.toString() ?? 'زبون';
              final content = m['address']?.toString() ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                phone,
                                style: const TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                tooltip: 'حذف الرسالة',
                                onPressed: () => _deleteMessage(msgId),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E3A8A),
                            ),
                            icon: const Icon(Icons.reply, size: 16),
                            label: const Text('رد داخل التطبيق'),
                            onPressed: () =>
                                _showReplyDialog(context, name, phone),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(
                              Icons.chat,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'رد عبر واتساب',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              final clean = phone.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );
                              final msg = Uri.encodeComponent(
                                'مرحباً $name، بخصوص استفسارك في متجر الأمين:',
                              );
                              html.window.open(
                                'https://wa.me/$clean?text=$msg',
                                '_blank',
                              );
                            },
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
    );
  }
}

class AdminReviewsScreen extends StatelessWidget {
  const AdminReviewsScreen({super.key});

  Future<void> _deleteReview(
    BuildContext context,
    dynamic id,
    VoidCallback reload,
  ) async {
    try {
      await supabase.from('product_reviews').delete().eq('id', id);
      reload();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ تم حذف التعليق بنجاح')));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة تعليقات وتقييمات الزبائن')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('product_reviews')
            .select()
            .order('id', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return const Center(
              child: Text('لا توجد تعليقات أو تقييمات حالياً'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reviews.length,
            itemBuilder: (_, i) {
              final r = reviews[i];
              final int rRating =
                  int.tryParse(r['rating']?.toString() ?? '5') ?? 5;
              return Card(
                child: ListTile(
                  title: Text(
                    'المنتج: ${r['product_name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'الكاتب: ${r['reviewer_name']}\nالتقييم: $rRating ⭐\nالتعليق: ${r['comment']}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteReview(
                      context,
                      r['id'],
                      () => (context as Element).markNeedsBuild(),
                    ),
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

class AdminManageProductsScreen extends StatefulWidget {
  const AdminManageProductsScreen({super.key});

  @override
  State<AdminManageProductsScreen> createState() =>
      _AdminManageProductsScreenState();
}

class _AdminManageProductsScreenState extends State<AdminManageProductsScreen> {
  late Future<List<Map<String, dynamic>>> _allProductsFuture;

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  void _loadAllProducts() {
    setState(() {
      _allProductsFuture = supabase
          .from('products')
          .select()
          .order('id', ascending: false)
          .then((d) => List<Map<String, dynamic>>.from(d));
    });
  }

  Future<void> _permanentDelete(dynamic id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
      _loadAllProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حذف المنتج نهائياً'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة منتجات المتجر (تحكم كامل)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAllProducts,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _allProductsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final products = snapshot.data ?? [];
          if (products.isEmpty)
            return const Center(child: Text('لا توجد منتجات مسجلة'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              final String title = p['name'] ?? p['title'] ?? 'منتج';
              final price = p['price'] ?? 0;
              final String imgUrl = p['image_url'] ?? p['image'] ?? '';

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: imgUrl.isNotEmpty
                      ? Image.network(
                          imgUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported, size: 40),
                        )
                      : const Icon(Icons.image, size: 50),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '$price د.ع | القسم: ${p['category'] ?? "عام"}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A)),
                        tooltip: 'تعديل',
                        onPressed: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProductScreen(product: p),
                            ),
                          );
                          if (res == true) _loadAllProducts();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'حذف',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: Text('هل تريد حذف المنتج "$title"؟'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('إلغاء'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _permanentDelete(p['id']);
                                  },
                                  child: const Text('حذف'),
                                ),
                              ],
                            ),
                          );
                        },
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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int currentOrdersCount = 0;
  int soldOrdersCount = 0;
  double totalSales = 0.0;
  double estimatedProfits = 0.0;
  double todaySales = 0.0;
  double weeklySales = 0.0;
  int newOrdersCount = 0;
  int completedOrdersCount = 0;
  int supportMsgsCount = 0;
  int reviewsCount = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final res = await supabase.from('orders').select();
      final list = List<Map<String, dynamic>>.from(res);

      final revRes = await supabase.from('product_reviews').select();
      final revList = List<Map<String, dynamic>>.from(revRes);

      int currentCount = 0;
      int soldCount = 0;
      double sales = 0;
      double today = 0;
      double week = 0;
      int msgs = 0;
      int newOrders = 0;
      int completedOrders = 0;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

      for (var item in list) {
        final status = item['status']?.toString() ?? '';
        if (status == 'رسالة دعم واردة') {
          msgs++;
        } else if (status == 'مُحذف (سلة المحذوفات)') {
          continue;
        } else if (status == 'تم التوصيل') {
          soldCount++;
          completedOrders++;
          sales += double.tryParse(item['price'].toString()) ?? 0.0;
        } else {
          currentCount++;
          if (status == 'قيد المراجعة') newOrders++;
        }
        final createdAt = DateTime.tryParse(
          item['created_at']?.toString() ?? '',
        );
        final orderPrice =
            double.tryParse(item['price']?.toString() ?? '0') ?? 0;
        if (createdAt != null && !createdAt.isBefore(todayStart)) {
          today += orderPrice;
        }
        if (createdAt != null && !createdAt.isBefore(weekStart)) {
          week += orderPrice;
        }
      }

      if (mounted) {
        setState(() {
          currentOrdersCount = currentCount;
          soldOrdersCount = soldCount;
          totalSales = sales;
          estimatedProfits = sales * 0.20;
          todaySales = today;
          weeklySales = week;
          newOrdersCount = newOrders;
          completedOrdersCount = completedOrders;
          supportMsgsCount = msgs;
          reviewsCount = revList.length;
          isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoadingStats = false);
    }
  }

  void _showEditStatsDialog() {
    final currentOrdersCtrl = TextEditingController(
      text: currentOrdersCount.toString(),
    );
    final soldOrdersCtrl = TextEditingController(
      text: soldOrdersCount.toString(),
    );
    final salesCtrl = TextEditingController(text: totalSales.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الإحصائيات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentOrdersCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الطلبات الحالية',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: soldOrdersCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الطلبات المباعة',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: salesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'إجمالي المبيعات (د.ع)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                currentOrdersCount =
                    int.tryParse(currentOrdersCtrl.text) ?? currentOrdersCount;
                soldOrdersCount =
                    int.tryParse(soldOrdersCtrl.text) ?? soldOrdersCount;
                totalSales = double.tryParse(salesCtrl.text) ?? totalSales;
                estimatedProfits = totalSales * 0.20;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ تم حفظ التعديل اليدوي للإحصائيات بنجاح'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('حفظ التعديل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'لوحة الإدارة والتحكم',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 26),
            tooltip: 'تعديل الإحصائيات',
            onPressed: _showEditStatsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: isLoadingStats
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📊 تعديل الإحصائيات والأرباح',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showEditStatsDialog,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('تعديل الأرقام'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 1,
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.shopping_bag_rounded,
                                size: 24,
                                color: Color(0xFF1E3A8A),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'الطلبات الحالية',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$currentOrdersCount',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Card(
                        elevation: 1,
                        color: Colors.indigo.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.done_all_rounded,
                                size: 24,
                                color: Colors.indigo,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'المباعة',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$soldOrdersCount',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Card(
                        elevation: 1,
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.attach_money_rounded,
                                size: 24,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'المبيعات',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$totalSales د.ع',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Card(
                        elevation: 1,
                        color: Colors.purple.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.trending_up_rounded,
                                size: 24,
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'الأرباح (20%)',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$estimatedProfits د.ع',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AdminMetricTile(
                      label: 'طلبات جديدة',
                      value: '$newOrdersCount',
                      color: Colors.orange,
                    ),
                    _AdminMetricTile(
                      label: 'طلبات مكتملة',
                      value: '$completedOrdersCount',
                      color: Colors.green,
                    ),
                    _AdminMetricTile(
                      label: 'مبيعات اليوم',
                      value: '$todaySales د.ع',
                      color: Colors.blue,
                    ),
                    _AdminMetricTile(
                      label: 'مبيعات الأسبوع',
                      value: '$weeklySales د.ع',
                      color: Colors.indigo,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminSupportMessagesScreen(),
                      ),
                    ).then((_) => _fetchStats());
                  },
                  child: Card(
                    elevation: 1,
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.mark_email_unread_rounded,
                                size: 28,
                                color: Colors.deepOrange,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'صندوق رسائل واستفسارات الزبائن',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ValueListenableBuilder<int>(
                                valueListenable: unreadAdminMessagesCount,
                                builder: (context, msgCount, _) => Badge(
                                  isLabelVisible: msgCount > 0,
                                  label: Text('$msgCount'),
                                  child: Text(
                                    '$supportMsgsCount',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.deepOrange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminReviewsScreen(),
                      ),
                    ).then((_) => _fetchStats());
                  },
                  child: Card(
                    elevation: 1,
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.rate_review_rounded,
                                size: 28,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'إدارة تعليقات وتقييمات المنتجات',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '$reviewsCount',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '⚙️ أقسام الإدارة والتحكم الكامل',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(
                      Icons.add_box_rounded,
                      color: Color(0xFF10B981),
                    ),
                    title: const Text(
                      'إضافة منتج جديد للمتجر',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
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
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'إرسال إشعار عام للزبائن (عبر جرس الإشعارات)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminSendNotificationScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(
                      Icons.inventory_rounded,
                      color: Colors.indigo,
                    ),
                    title: const Text(
                      'إدارة المنتجات وتعديلها (تحكم كامل ونفاد الكمية)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminManageProductsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.orange,
                    ),
                    title: const Text(
                      'سلة محذوفات المنتجات والطلبات',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminTrashProductsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(
                      Icons.email_rounded,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'صندوق رسائل واستفسارات الزبائن',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminSupportMessagesScreen(),
                        ),
                      ).then((_) => _fetchStats());
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'تسجيل الخروج من حساب المدير',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () async {
                      await supabase.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthLandingScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _AdminMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final MaterialColor color;

  const _AdminMetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color.shade700)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
