import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StokEklePage extends StatefulWidget {
  const StokEklePage({super.key});

  @override
  State<StokEklePage> createState() => _StokEklePageState();
}

class _StokEklePageState extends State<StokEklePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _stokKoduController = TextEditingController();
  final TextEditingController _stokAdiController = TextEditingController();
  final TextEditingController _kisaIsimController = TextEditingController();
  final TextEditingController _anaGrupController = TextEditingController();
  final TextEditingController _altGrupController = TextEditingController();
  final TextEditingController _markaController = TextEditingController();
  final TextEditingController _ureticiController = TextEditingController();
  final TextEditingController _reyonController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();

  // Artık açıklama düzenlenebilir
  final TextEditingController _aciklamaController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final Map<String, dynamic> yeniStok = {
      'StokKodu': _stokKoduController.text.trim(),
      'StokAdi': _stokAdiController.text.trim(),
      'KisaIsim': _kisaIsimController.text.trim(),
      'AnaGrup': _anaGrupController.text.trim(),
      'AltGrup': _altGrupController.text.trim(),
      'Marka': _markaController.text.trim(),
      'Uretici': _ureticiController.text.trim(),
      'Reyon': _reyonController.text.trim(),
      'Fiyat': double.tryParse(_fiyatController.text.trim()) ?? 0,
      'Aciklama': _aciklamaController.text
          .trim(), // AÇIKLAMA BURADA GÖNDERİLİYOR
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/stoklar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(yeniStok),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok başarıyla eklendi!')),
        );
        Navigator.pop(context, true);
      } else {
        final jsonResp = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              jsonResp['hatalar']?.join('\n') ??
              'Hata oluştu: ${response.statusCode}';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
        _isSaving = false;
      });
    }
  }

  Widget _modernTextField(
    TextEditingController controller,
    String label,
    bool zorunlu, {
    IconData? icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.deepPurple.withOpacity(0.07),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.deepPurple)
                : null,
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (val) {
            if (zorunlu && (val == null || val.isEmpty)) {
              return '$label boş olamaz';
            }
            return null;
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stokKoduController.dispose();
    _stokAdiController.dispose();
    _kisaIsimController.dispose();
    _anaGrupController.dispose();
    _altGrupController.dispose();
    _markaController.dispose();
    _ureticiController.dispose();
    _reyonController.dispose();
    _fiyatController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade700,
        title: const Text(
          'Yeni Stok Ekle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _modernTextField(
                  _stokKoduController,
                  'Stok Kodu',
                  true,
                  icon: Icons.qr_code,
                ),
                _modernTextField(
                  _stokAdiController,
                  'Stok Adı',
                  true,
                  icon: Icons.text_fields,
                ),
                _modernTextField(
                  _kisaIsimController,
                  'Kısa İsim',
                  false,
                  icon: Icons.short_text,
                ),
                _modernTextField(
                  _anaGrupController,
                  'Ana Grup',
                  false,
                  icon: Icons.category,
                ),
                _modernTextField(
                  _altGrupController,
                  'Alt Grup',
                  false,
                  icon: Icons.label,
                ),
                _modernTextField(
                  _markaController,
                  'Marka',
                  false,
                  icon: Icons.business,
                ),
                _modernTextField(
                  _ureticiController,
                  'Üretici',
                  false,
                  icon: Icons.factory,
                ),
                _modernTextField(
                  _reyonController,
                  'Reyon',
                  false,
                  icon: Icons.store,
                ),
                _modernTextField(
                  _fiyatController,
                  'Fiyat',
                  true,
                  icon: Icons.price_change,
                  keyboardType: TextInputType.number,
                ),
                _modernTextField(
                  _aciklamaController,
                  'Açıklama',
                  false,
                  icon: Icons.info_outline,
                  maxLines: 5,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: _isSaving
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.deepPurple,
                          ),
                        )
                      : ElevatedButton(
                          style:
                              ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                backgroundColor: null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                elevation: 4,
                              ).copyWith(
                                backgroundColor:
                                    MaterialStateProperty.resolveWith<Color?>(
                                      (states) => null,
                                    ),
                                foregroundColor:
                                    MaterialStateProperty.all<Color>(
                                      Colors.white,
                                    ),
                              ),
                          onPressed: _kaydet,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurple,
                                  Colors.blue.shade400,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              height: 54,
                              child: const Text('Kaydet'),
                            ),
                          ),
                        ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    color: Colors.red.shade100,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
