import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CariOlusturPage extends StatefulWidget {
  const CariOlusturPage({super.key});

  @override
  State<CariOlusturPage> createState() => _CariOlusturPageState();
}

class _CariOlusturPageState extends State<CariOlusturPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'Cari Kodu': TextEditingController(),
    'Ünvan 1': TextEditingController(),
    'Ünvan 2': TextEditingController(),
    'Vergi Dairesi': TextEditingController(),
    'Vergi No': TextEditingController(),
    'E-Posta': TextEditingController(),
    'Cep Tel': TextEditingController(),
    'Web Adresi': TextEditingController(),
    'Temsilci Kodu': TextEditingController(),
    'Grup Kodu': TextEditingController(),
    'Sektör Kodu': TextEditingController(),
    'Ödeme Planı No': TextEditingController(),
    'Fatura Adres No': TextEditingController(),
  };

  bool _isLoading = false;
  List<String> _serverErrors = [];

  String? _secilenDoviz; // Ana döviz cinsi
  String? _secilenDoviz1; // Döviz Cinsi 1
  String? _secilenDoviz2; // Döviz Cinsi 2

  final Map<String, int> _dovizHarita = {
    'TL Türk Lirası': 0,
    'USD Amerikan Doları': 1,
    'EUR Euro': 2,
  };

  final Map<String, IconData> _fieldIcons = {
    'Cari Kodu': Icons.code,
    'Ünvan 1': Icons.business,
    'Ünvan 2': Icons.business_outlined,
    'Vergi Dairesi': Icons.account_balance,
    'Vergi No': Icons.numbers,
    'E-Posta': Icons.email,
    'Cep Tel': Icons.phone_android,
    'Web Adresi': Icons.language,
    'Temsilci Kodu': Icons.person,
    'Grup Kodu': Icons.group,
    'Sektör Kodu': Icons.business_center,
    'Ödeme Planı No': Icons.payment,
    'Fatura Adres No': Icons.home,
  };

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    int? secilenDovizKodu = _dovizHarita[_secilenDoviz];
    int? secilenDoviz1Kodu = _dovizHarita[_secilenDoviz1];
    int? secilenDoviz2Kodu = _dovizHarita[_secilenDoviz2];

    final url = Uri.parse('http://10.0.2.2:5000/cariler');
    final body = {
      ...Map.fromEntries(
        _controllers.entries.map(
          (e) => MapEntry(_keyToJsonField(e.key), e.value.text.trim()),
        ),
      ),
      'cari_doviz_cinsi': secilenDovizKodu?.toString() ?? '0',
      'cari_doviz_cinsi1': secilenDoviz1Kodu?.toString() ?? '0',
      'cari_doviz_cinsi2': secilenDoviz2Kodu?.toString() ?? '0',
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final jsonResp = jsonDecode(response.body);
      if (response.statusCode == 201 && jsonResp['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cari başarıyla oluşturuldu.')),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _serverErrors = List<String>.from(
            jsonResp['hatalar'] ?? ['Bilinmeyen hata'],
          );
        });
      }
    } catch (e) {
      setState(() => _serverErrors = ['Bağlantı hatası: $e']);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _keyToJsonField(String key) {
    final map = {
      'Cari Kodu': 'cari_kod',
      'Ünvan 1': 'cari_unvan1',
      'Ünvan 2': 'cari_unvan2',
      'Vergi Dairesi': 'cari_vdaire_adi',
      'Vergi No': 'cari_VergiKimlikNo',
      'E-Posta': 'cari_EMail',
      'Cep Tel': 'cari_CepTel',
      'Web Adresi': 'cari_wwwadresi',
      'Temsilci Kodu': 'cari_temsilci_kodu',
      'Grup Kodu': 'cari_grup_kodu',
      'Sektör Kodu': 'cari_sektor_kodu',
      'Ödeme Planı No': 'cari_odemeplan_no',
      'Fatura Adres No': 'cari_fatura_adres_no',
    };
    return map[key] ?? key;
  }

  Widget _buildCardField(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.blue.shade50,
        child: TextFormField(
          controller: _controllers[label],
          validator: required
              ? (val) =>
                    val == null || val.trim().isEmpty ? '$label zorunlu' : null
              : null,
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            prefixIcon: Icon(_fieldIcons[label], color: Colors.blue.shade400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.blue.shade50,
        child: DropdownButtonFormField<String>(
          value: _secilenDoviz,
          items: _dovizHarita.keys
              .map(
                (label) => DropdownMenuItem(child: Text(label), value: label),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _secilenDoviz = value);
          },
          decoration: InputDecoration(
            labelText: 'Döviz Cinsi *',
            prefixIcon: Icon(Icons.money, color: Colors.blue.shade400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (value) => value == null ? 'Döviz cinsi seçiniz' : null,
        ),
      ),
    );
  }

  Widget _buildDropdownField1() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.blue.shade50,
        child: DropdownButtonFormField<String>(
          value: _secilenDoviz1,
          items: _dovizHarita.keys
              .map(
                (label) => DropdownMenuItem(child: Text(label), value: label),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _secilenDoviz1 = value);
          },
          decoration: InputDecoration(
            labelText: 'Döviz Cinsi 1',
            prefixIcon: Icon(Icons.money, color: Colors.blue.shade400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField2() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.blue.shade50,
        child: DropdownButtonFormField<String>(
          value: _secilenDoviz2,
          items: _dovizHarita.keys
              .map(
                (label) => DropdownMenuItem(child: Text(label), value: label),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _secilenDoviz2 = value);
          },
          decoration: InputDecoration(
            labelText: 'Döviz Cinsi 2',
            prefixIcon: Icon(Icons.money_outlined, color: Colors.blue.shade400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContainer() {
    if (_serverErrors.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.redAccent, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _serverErrors
            .map(
              (e) => Text("• $e", style: const TextStyle(color: Colors.white)),
            )
            .toList(),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF1F6F9),
      appBar: AppBar(
        title: const Text(
          'Yeni Cari Oluştur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blue.shade900,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              const SizedBox(height: 10),
              _buildErrorContainer(),

              // Temel Bilgiler
              Text(
                'Temel Bilgiler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              _buildCardField('Cari Kodu', required: true),
              _buildCardField('Ünvan 1', required: true),
              _buildCardField('Ünvan 2'),

              // İletişim Bilgileri
              const SizedBox(height: 20),
              Text(
                'İletişim Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              _buildCardField('E-Posta'),
              _buildCardField('Cep Tel'),
              _buildCardField('Web Adresi'),

              // Ana Döviz Cinsi Dropdown
              const SizedBox(height: 20),
              Text(
                'Döviz Cinsi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              _buildDropdownField(),

              // Gelişmiş
              const SizedBox(height: 20),
              Text(
                'Gelişmiş Bilgiler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              ExpansionTile(
                title: const Text('Gelişmiş Alanları Göster'),
                children: [
                  _buildCardField('Vergi Dairesi'),
                  _buildCardField('Vergi No'),
                  _buildDropdownField1(),
                  _buildDropdownField2(),
                  _buildCardField('Temsilci Kodu'),
                  _buildCardField('Grup Kodu'),
                  _buildCardField('Sektör Kodu'),
                  _buildCardField('Ödeme Planı No'),
                  _buildCardField('Fatura Adres No'),
                ],
              ),

              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _kaydet,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          backgroundColor: Colors.blue.shade700,
                          elevation: 8,
                        ),
                        icon: const Icon(Icons.save, size: 24),
                        label: const Text(
                          'Kaydet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
