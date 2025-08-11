import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StokDetayPage extends StatefulWidget {
  final String stokKodu;

  const StokDetayPage({super.key, required this.stokKodu});

  @override
  State<StokDetayPage> createState() => _StokDetayPageState();
}

class _StokDetayPageState extends State<StokDetayPage> {
  Map<String, dynamic>? stok;
  bool isLoading = true;
  String? errorMessage;

  // Vergi koduna göre KDV oranı döner
  double getKdvOrani(int vergiKodu) {
    switch (vergiKodu) {
      case 1:
        return 0.0; // Vergi yok
      case 2:
        return 0.01; // %1
      case 3:
        return 0.10; // %10
      case 4:
        return 0.20; // %20
      default:
        return 0.0; // Bilinmeyen vergi kodu için 0 kabul edilir
    }
  }

  Future<void> fetchStok() async {
    final url = Uri.parse(
      'http://10.0.2.2:5000/stoklar/ara?q=${widget.stokKodu}',
    );
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          stok = data;
          isLoading = false;
          errorMessage = null;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'Stok bulunamadı.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Sunucudan veri alınamadı. Hata kodu: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Bir hata oluştu: $e';
        isLoading = false;
      });
    }
  }

  String? fiyatFormatla(num? fiyat) {
    if (fiyat == null) return null;
    return fiyat.toStringAsFixed(2) + ' ₺';
  }

  double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  Widget buildInfoRow(String label, String? value, {IconData? icon}) {
    if (value == null || value.isEmpty || value == '-')
      return SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 2,
      child: ListTile(
        leading: icon != null ? Icon(icon, color: Colors.brown.shade700) : null,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          value,
          style: const TextStyle(color: Colors.blue, fontSize: 16),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchStok();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stok Bilgileri'),
          backgroundColor: Colors.brown.shade700,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stok Bilgileri'),
          backgroundColor: Colors.brown.shade700,
        ),
        body: Center(child: Text(errorMessage!)),
      );
    }

    final fiyatKdvDahil = parseDouble(stok?['Fiyat']);
    final vergiKodu = stok?['VergiKodu'] is int
        ? stok!['VergiKodu']
        : int.tryParse(stok?['VergiKodu']?.toString() ?? '1') ?? 1;
    final kdvOrani = getKdvOrani(vergiKodu);
    final fiyatKdvHaric = fiyatKdvDahil != null && kdvOrani != 0
        ? fiyatKdvDahil / (1 + kdvOrani)
        : fiyatKdvDahil;
    final gorselUrl = stok?['ResimUrl'];

    final aciklama = stok?['Aciklama'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok Bilgileri'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.95, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.scale(scale: value, child: child),
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: gorselUrl != null && gorselUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    gorselUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.inventory_2,
                                  size: 48,
                                  color: Colors.deepPurple,
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          stok?['StokAdi'] ?? '-',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stok?['StokKodu'] ?? '-',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF828282),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                fiyatFormatla(fiyatKdvDahil) ?? '-',
                                style: const TextStyle(
                                  color: Color(0xFF219653),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Mevcut: ${stok?['MevcutMiktar'] ?? '-'}',
                                style: const TextStyle(
                                  color: Color(0xFF2F80ED),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.percent,
                              size: 18,
                              color: Color(0xFFF2994A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'KDV: %${(kdvOrani * 100).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFF2994A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Birim: ${stok?['Birim'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF828282),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Diğer detaylar kutucuklar halinde
              buildInfoRow(
                'Kısa İsmi',
                stok?['KisaIsim'],
                icon: Icons.short_text,
              ),
              buildInfoRow('Ana Grup', stok?['AnaGrup'], icon: Icons.category),
              buildInfoRow(
                'Alt Grup',
                stok?['AltGrup'],
                icon: Icons.subdirectory_arrow_right,
              ),
              buildInfoRow(
                'Marka',
                stok?['Marka'],
                icon: Icons.branding_watermark,
              ),
              buildInfoRow('Üretici', stok?['Uretici'], icon: Icons.factory),
              buildInfoRow('Reyon', stok?['Reyon'], icon: Icons.store),
              buildInfoRow(
                'Vergi Kodu',
                vergiKodu.toString(),
                icon: Icons.percent,
              ),
              buildInfoRow(
                'Fiyat (KDV Hariç)',
                fiyatFormatla(fiyatKdvHaric),
                icon: Icons.money_off,
              ),
              const SizedBox(height: 24),

              // Açıklama kısmı geniş kutu
              if (aciklama.isNotEmpty)
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Açıklama',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aciklama,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
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
    );
  }
}
