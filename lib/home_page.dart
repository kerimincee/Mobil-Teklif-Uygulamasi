import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'cariler_page.dart';
import 'cari_ekle_page.dart';
import 'stoklar_page.dart';
import 'barkod_okuyucu_page.dart';
import 'stok_detay_page.dart';
import 'siparis_sayfasi.dart';
import 'pdf_list_page.dart'; // Yeni eklenen pdf sayfası importu

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showSearchDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Stok Arama'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Stok kodu veya adı yazın',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final query = _controller.text.trim();
              if (query.isEmpty) return;
              Navigator.pop(context);

              final url = Uri.parse(
                'http://10.0.2.2:5000/stoklar/ara?q=$query',
              );
              try {
                final response = await http.get(url);
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  if (data["StokKodu"] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StokDetayPage(stokKodu: data["StokKodu"]),
                      ),
                    );
                  } else {
                    _showMessage(context, 'Stok bulunamadı.');
                  }
                } else {
                  _showMessage(context, 'Stok bulunamadı.');
                }
              } catch (e) {
                _showMessage(context, 'Arama sırasında hata oluştu: $e');
              }
            },
            child: const Text('Ara'),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Bilgi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showStoklarDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.brown.shade800, Colors.brown.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Stoklar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _stokItem(
                  context,
                  label: 'Stok detayı',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StoklarPage()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _stokItem(
                  context,
                  label: 'Fiyat gör (Barkod)',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarkodOkuyucuPage(),
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
  }

  Widget _stokItem(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.brown.shade700, Colors.brown.shade600],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 28),
          width: double.infinity,
          child: Column(
            children: [
              const Icon(
                Icons.insert_chart,
                color: Colors.orangeAccent,
                size: 52,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCarilerDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.brown.shade900, Colors.brown.shade700],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _cariBlock(
                        context,
                        label: 'Yeni cari oluştur',
                        color: Colors.green.shade900,
                        icon: Icons.note_add,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CariOlusturPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _cariBlock(
                        context,
                        label: 'Cari detayı',
                        color: Colors.brown.shade700,
                        icon: Icons.bar_chart,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CarilerPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cari hesaplar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 32,
                        ),
                        onPressed: () => Navigator.pop(context),
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
  }

  Widget _cariBlock(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 36),
            width: double.infinity,
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 52),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _slideAnimation.value.dy)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Card(
              elevation: 12,
              shadowColor: (color ?? Colors.blueAccent).withOpacity(0.4),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                splashColor: (color ?? Colors.blueAccent).withOpacity(0.3),
                child: Container(
                  height: 180,
                  width: 170,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (color ?? Colors.blueAccent).withOpacity(0.1),
                        (color ?? Colors.blueAccent).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (color ?? Colors.blueAccent).withOpacity(0.2),
                              (color ?? Colors.blueAccent).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          size: 56,
                          color: color ?? Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color ?? Colors.blueAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.indigo.shade700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade50,
              Colors.indigo.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Analiz Otomasyon',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        size: 28,
                        color: Colors.white,
                      ),
                      tooltip: 'Arama',
                      onPressed: () => _showSearchDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        size: 28,
                        color: Colors.white,
                      ),
                      tooltip: 'Barkod Okuyucu',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BarkodOkuyucuPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Analiz Otomasyon',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF222B45),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sipariş, stok ve cari işlemlerinizi kolayca yönetin.',
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(0xFF828282),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children: [
                            _glassMenuCard(
                              context,
                              icon: Icons.discount,
                              label: 'Teklif Ver',
                              color: Colors.green.shade600,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SiparisSayfasi(),
                                  ),
                                );
                              },
                            ),
                            _glassMenuCard(
                              context,
                              icon: Icons.people,
                              label: 'Cari Hesaplar',
                              color: Colors.deepOrange.shade400,
                              onTap: () => _showCarilerDialog(context),
                            ),
                            _glassMenuCard(
                              context,
                              icon: Icons.inventory,
                              label: 'Stoklar',
                              color: Colors.teal.shade400,
                              onTap: () => _showStoklarDialog(context),
                            ),
                            // PDF butonu eklendi:
                            _glassMenuCard(
                              context,
                              icon: Icons.pinch_rounded,
                              label: 'Teklif Onayla',
                              color: Colors.red.shade600,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PdfListPage(),
                                  ),
                                );
                              },
                            ),
                          ],
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

  Widget _glassMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _slideAnimation.value.dy)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 170,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.13),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: color.withOpacity(0.13),
                    width: 1.5,
                  ),
                  backgroundBlendMode: BlendMode.luminosity,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.4),
                            color.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icon, size: 48, color: color),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
