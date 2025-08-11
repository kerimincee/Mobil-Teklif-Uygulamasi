import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'stok_detay_page.dart';
import 'stok_ekle_page.dart';

class StoklarPage extends StatefulWidget {
  const StoklarPage({super.key});

  @override
  State<StoklarPage> createState() => _StoklarPageState();
}

class _StoklarPageState extends State<StoklarPage> {
  List<dynamic> stoklar = [];
  List<dynamic> filtreliStoklar = [];
  bool isLoading = true;
  String? errorMessage;
  String arama = "";

  // Sıralama için
  String _sortBy = 'isim'; // 'isim' veya 'fiyat'
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    fetchStoklar();
  }

  Future<void> fetchStoklar() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse(
      'http://10.0.2.2:5000/stoklar?depo_no=1&fiyat_listesi_no=1',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          stoklar = data;
          _applyFilterAndSort();
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

  void _filtrele(String input) {
    setState(() {
      arama = input;
      _applyFilterAndSort();
    });
  }

  void _applyFilterAndSort() {
    filtreliStoklar = stoklar.where((stok) {
      final ad = (stok['StokAdi'] ?? '').toString().toLowerCase();
      return ad.contains(arama.toLowerCase());
    }).toList();

    filtreliStoklar.sort((a, b) {
      int cmp;
      if (_sortBy == 'isim') {
        cmp = a['StokAdi'].toString().toLowerCase().compareTo(
          b['StokAdi'].toString().toLowerCase(),
        );
      } else {
        double fiyatA = double.tryParse(a['Fiyat']?.toString() ?? '0') ?? 0.0;
        double fiyatB = double.tryParse(b['Fiyat']?.toString() ?? '0') ?? 0.0;
        cmp = fiyatA.compareTo(fiyatB);
      }
      return _ascending ? cmp : -cmp;
    });
  }

  Future<void> _showSortDialog() async {
    String tempSortBy = _sortBy;
    bool tempAscending = _ascending;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Sıralama Seçenekleri'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('İsme Göre'),
                    value: 'isim',
                    groupValue: tempSortBy,
                    onChanged: (val) => setStateDialog(() => tempSortBy = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Fiyata Göre'),
                    value: 'fiyat',
                    groupValue: tempSortBy,
                    onChanged: (val) => setStateDialog(() => tempSortBy = val!),
                  ),
                  SwitchListTile(
                    title: Text(tempAscending ? 'Artan' : 'Azalan'),
                    value: tempAscending,
                    onChanged: (val) =>
                        setStateDialog(() => tempAscending = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'sortBy': tempSortBy,
                    'ascending': tempAscending,
                  }),
                  child: const Text('Uygula'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _sortBy = result['sortBy'];
        _ascending = result['ascending'];
        _applyFilterAndSort();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stoklar'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stoklar'), centerTitle: true),
        body: Center(child: Text(errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stoklar'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showSortDialog,
            icon: const Icon(Icons.sort_by_alpha),
            tooltip: 'Sırala',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final eklemeBasarili = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const StokEklePage()),
          );
          if (eklemeBasarili == true) {
            fetchStoklar();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Yeni Stok Ekle',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filtrele,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Stok adına göre ara...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: filtreliStoklar.length,
              itemBuilder: (context, index) {
                final stok = filtreliStoklar[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.95, end: 1),
                  duration: Duration(milliseconds: 400 + index * 60),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: Transform.scale(scale: value, child: child),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StokDetayPage(
                              stokKodu: stok['StokKodu'].toString(),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade50,
                              Colors.blue.shade50,
                            ],
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
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.inventory_2,
                                  size: 32,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      stok['StokAdi'] ?? 'Stok Adı Yok',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF222B45),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '${stok['Fiyat'] ?? '0,00'} TL',
                                            style: const TextStyle(
                                              color: Color(0xFF219653),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Mevcut: ${stok['MevcutMiktar'] ?? '0'}',
                                            style: TextStyle(
                                              color: Color(0xFF2F80ED),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.percent,
                                          size: 15,
                                          color: Color(0xFFF2994A),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'İskonto: ${stok['Iskonto'] ?? 'Yok'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFF2994A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${stok['StokKodu'] ?? 'Kod yok'} • ${stok['Birim'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF828282),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
