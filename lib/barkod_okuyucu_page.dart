import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'stok_detay_page.dart';

class BarkodOkuyucuPage extends StatefulWidget {
  const BarkodOkuyucuPage({Key? key}) : super(key: key);

  @override
  _BarkodOkuyucuPageState createState() => _BarkodOkuyucuPageState();
}

class _BarkodOkuyucuPageState extends State<BarkodOkuyucuPage> {
  String scannedBarcode = '';
  final TextEditingController _manualBarcodeController = TextEditingController();
  bool _isLoading = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _manualBarcodeController.dispose();
    super.dispose();
  }

  Future<void> _getProductByBarcodeAndNavigate(String barcode) async {
    if (_isLoading) return; // Çift tıklamayı önle

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://10.0.2.2:5000/stoklar/barkod/$barcode');

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Bağlantı zaman aşımına uğradı');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (mounted) {
          // StokDetayPage'e geç
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StokDetayPage(stokKodu: data['StokKodu']),
            ),
          ).then((_) {
            if (mounted) {
              setState(() {
                scannedBarcode = '';
                _manualBarcodeController.clear();
              });
            }
          });
        }
      } else {
        final errorData = json.decode(response.body);
        _showErrorDialog(errorData['message'] ?? 'Ürün bulunamadı.');
      }
    } catch (e) {
      _showErrorDialog('Hata: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleManualBarcodeSearch() {
    final code = _manualBarcodeController.text.trim();
    if (code.isNotEmpty && !_isLoading) {
      setState(() {
        scannedBarcode = code;
      });
      _getProductByBarcodeAndNavigate(code);
    }
  }

  void _handleScannedBarcode(String code) {
    if (code != scannedBarcode && !_isLoading) {
      setState(() {
        scannedBarcode = code;
      });
      _getProductByBarcodeAndNavigate(code);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkod Okuyucu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController?.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_rear),
            onPressed: () => _scannerController?.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (BarcodeCapture capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final code = barcodes.first.rawValue ?? '';
                      if (code.isNotEmpty) {
                        _handleScannedBarcode(code);
                      }
                    }
                  },
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Okunan Barkod:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    scannedBarcode.isEmpty ? '-' : scannedBarcode,
                    style: TextStyle(
                      fontSize: 16,
                      color: scannedBarcode.isEmpty
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualBarcodeController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Barkod kodunu girin',
                            prefixIcon: Icon(Icons.qr_code_scanner),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _handleManualBarcodeSearch(),
                        ),
                      ),
                      SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleManualBarcodeSearch,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: _isLoading 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text('Ara'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
