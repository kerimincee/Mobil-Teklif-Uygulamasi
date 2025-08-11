import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'siparisler_page.dart';

class CarilerPage extends StatefulWidget {
  const CarilerPage({super.key});

  @override
  State<CarilerPage> createState() => _CarilerPageState();
}

class _CarilerPageState extends State<CarilerPage> {
  List<dynamic> cariler = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> fetchCariler() async {
    final url = Uri.parse('http://10.0.2.2:5000/cariler');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          cariler = data;
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

  @override
  void initState() {
    super.initState();
    fetchCariler();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Cari Seçimi'),
        backgroundColor: Colors.brown.shade800,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : ListView.builder(
              itemCount: cariler.length,
              itemBuilder: (context, index) {
                final cari = cariler[index];
                return _buildCariCard(cari, context);
              },
            ),
    );
  }

  Widget _buildCariCard(dynamic cari, BuildContext context) {
    final bakiye = (cari['Bakiye'] ?? 0).toDouble();
    final bakiyeDurumu = (cari['BakiyeDurumu'] ?? '').toString().toLowerCase();
    Color bakiyeRenk;

    if (bakiyeDurumu == 'borçlu') {
      bakiyeRenk = Colors.red;
    } else if (bakiyeDurumu == 'alacaklı') {
      bakiyeRenk = Colors.green;
    } else {
      bakiyeRenk = Colors.black87;
    }

    return Card(
      color: Colors.grey.shade50,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CariDetayPage(cariKodu: cari['CariKodu']),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cari['CariKodu'] ?? 'Kod Yok',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cari['CariAdi'] ?? 'Cari Adı Yok',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Müşteri\nMal ve Hizmet alınır satılır',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bakiye: ${bakiye.toStringAsFixed(2)} TL (${bakiyeDurumu.isNotEmpty ? bakiyeDurumu[0].toUpperCase() + bakiyeDurumu.substring(1) : 'Bakiye Yok'})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: bakiyeRenk,
                ),
              ),
              const SizedBox(height: 8),
              _buildParaSatiri('USD', cari['USD'], cari['DurumUSD']),
              _buildParaSatiri('EUR', cari['EUR'], cari['DurumEUR']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParaSatiri(String birim, dynamic miktar, String? durum) {
    Color renk;
    if ((durum ?? '').toLowerCase() == 'borçlu') {
      renk = Colors.red;
    } else if ((durum ?? '').toLowerCase() == 'alacaklı') {
      renk = Colors.green;
    } else {
      renk = Colors.black87;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        '${(miktar ?? 0).toStringAsFixed(2)} $birim ${durum != null ? '($durum)' : ''}',
        style: TextStyle(fontWeight: FontWeight.bold, color: renk),
      ),
    );
  }
}
