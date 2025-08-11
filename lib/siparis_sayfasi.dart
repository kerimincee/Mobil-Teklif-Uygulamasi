import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SiparisSayfasi extends StatefulWidget {
  const SiparisSayfasi({super.key});

  @override
  _SiparisSayfasiState createState() => _SiparisSayfasiState();
}

class _SiparisSayfasiState extends State<SiparisSayfasi>
    with TickerProviderStateMixin {
  String? secilenCari;
  String? secilenUrun;

  List<Map<String, dynamic>> cariler = [];
  List<Map<String, dynamic>> urunler = [];

  final TextEditingController miktarController = TextEditingController();
  final TextEditingController brutFiyatController = TextEditingController();
  final TextEditingController iskonto1Controller = TextEditingController();
  final TextEditingController iskonto2Controller = TextEditingController();
  final TextEditingController kdvController = TextEditingController();
  final TextEditingController ekstraAciklamaController =
      TextEditingController();
  final TextEditingController teklifIcerigiController = TextEditingController();
  final TextEditingController ilgiliKisiController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  List<Map<String, dynamic>> eklenenUrunler = [];

  // Kablo tesisatı aktivasyon için yeni değişkenler
  bool kabloTesisatiAktif = false;
  final TextEditingController kabloTesisatiFiyatController = TextEditingController();
  Map<String, dynamic>? kabloTesisatiUrunu;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    iskonto1Controller.addListener(_onIskontoChanged);
    iskonto2Controller.addListener(_onIskontoChanged);
    kabloTesisatiFiyatController.addListener(_onKabloTesisatiFiyatChanged);
    veriGetir();
  }

  @override
  void dispose() {
    _animationController.dispose();
    iskonto1Controller.removeListener(_onIskontoChanged);
    iskonto2Controller.removeListener(_onIskontoChanged);
    kabloTesisatiFiyatController.dispose();
    super.dispose();
  }

  void _onIskontoChanged() {
    if (iskonto1Controller.text.isNotEmpty &&
        iskonto2Controller.text.isNotEmpty) {
      if (iskonto1Controller.text.length > iskonto2Controller.text.length) {
        iskonto2Controller.clear();
      } else {
        iskonto1Controller.clear();
      }
    }
  }

  void _onKabloTesisatiToggle(bool value) {
    setState(() {
      kabloTesisatiAktif = value;
      if (value && kabloTesisatiUrunu == null) {
        // İlk kez aktif edildiğinde ürünü oluştur
        kabloTesisatiUrunu = {
          'stokAdi': 'Kablo Tesisatı, Montaj, Aktivasyon, Kurulum',
          'aciklama': 'Kablo tesisatı, montaj, aktivasyon ve kurulum hizmetleri',
          'miktar': '1',
          'brutFiyat': '0',
          'iskonto1': '0',
          'iskonto2': '0',
          'kdv': '0',
          'toplam': '0',
          'imagePath': null,
        };
      }
    });
  }

  void _onKabloTesisatiFiyatChanged() {
    if (kabloTesisatiAktif && kabloTesisatiUrunu != null) {
      double fiyat = double.tryParse(kabloTesisatiFiyatController.text) ?? 0;
      setState(() {
        kabloTesisatiUrunu!['brutFiyat'] = fiyat.toString();
        kabloTesisatiUrunu!['toplam'] = fiyat.toStringAsFixed(2);
      });
    }
  }

  Future<void> uploadPdf(File file) async {
    var uri = Uri.parse(
      'http://10.0.2.2:5000/pdf/upload',
    ); // Emülatörde çalışıyorsan
    var request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['teklif_icerigi'] = teklifIcerigiController.text;
    var response = await request.send();

    if (response.statusCode == 200) {
      print("✅ PDF başarıyla sunucuya yüklendi.");
    } else {
      print("❌ Hata oluştu: ${response.statusCode}");
    }
  }

  // Fotoğraf seçme fonksiyonu
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilirken hata oluştu: $e')),
      );
    }
  }

  // Fotoğraf kaldırma fonksiyonu
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> veriGetir() async {
    try {
      final cariResponse = await http.get(
        Uri.parse('http://10.0.2.2:5000/cariler'),
      );
      if (cariResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(cariResponse.body);
        setState(() {
          cariler = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }

      final urunResponse = await http.get(
        Uri.parse('http://10.0.2.2:5000/stoklar'),
      );
      if (urunResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(urunResponse.body);
        setState(() {
          urunler = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  double hesaplaToplamUrun(Map<String, dynamic> urun) {
    double miktar = double.tryParse(urun['miktar'] ?? '0') ?? 0;
    double brutFiyat = double.tryParse(urun['brutFiyat'] ?? '0') ?? 0;
    double iskonto1 = double.tryParse(urun['iskonto1'] ?? '0') ?? 0;
    double iskonto2 = double.tryParse(urun['iskonto2'] ?? '0') ?? 0;
    double kdv = double.tryParse(urun['kdv'] ?? '0') ?? 0;

    double fiyatKdvli = brutFiyat + (brutFiyat * kdv / 100);
    double fiyatIndirimli = fiyatKdvli * (1 - iskonto1 / 100);
    double toplam = fiyatIndirimli * miktar - iskonto2;

    return toplam < 0 ? 0 : toplam;
  }

  void urunEkle() {
    if (secilenUrun == null) return;

    // Zorunlu alanları kontrol et
    if (secilenCari == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cari seçimi zorunludur!')),
      );
      return;
    }

    if (miktarController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Miktar alanı zorunludur!')),
      );
      return;
    }

    if (brutFiyatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brüt fiyat alanı zorunludur!')),
      );
      return;
    }

    if (teklifIcerigiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teklif içeriği alanı zorunludur!')),
      );
      return;
    }

    final stok = urunler.firstWhere(
      (u) => u['StokKodu'] == secilenUrun,
      orElse: () => {'StokAdi': secilenUrun},
    );
    final stokAdi = stok['StokAdi'];
    final stokImagePath = stok['imagePath']; // Stoktan fotoğraf yolu
    final stokAciklama = stok['Aciklama'] ?? '';

    final urun = {
      'stokAdi': stokAdi,
      'aciklama': stokAciklama,
      'miktar': miktarController.text,
      'brutFiyat': brutFiyatController.text,
      'iskonto1': iskonto1Controller.text,
      'iskonto2': iskonto2Controller.text,
      'kdv': kdvController.text,
      'toplam': hesaplaToplamUrun({
        'miktar': miktarController.text,
        'brutFiyat': brutFiyatController.text,
        'iskonto1': iskonto1Controller.text,
        'iskonto2': iskonto2Controller.text,
        'kdv': kdvController.text,
      }).toStringAsFixed(2),
      'imagePath':
          _selectedImage?.path ??
          (stokImagePath is String && stokImagePath.isNotEmpty
              ? stokImagePath
              : null),
    };

    setState(() {
      eklenenUrunler.add(urun);
      miktarController.clear();
      brutFiyatController.clear();
      iskonto1Controller.clear();
      iskonto2Controller.clear();
      kdvController.clear();
      _selectedImage = null; // Fotoğrafı temizle
    });
  }

  double genelToplam() {
    double urunlerToplami = eklenenUrunler.fold(
      0,
      (sum, urun) => sum + double.tryParse(urun['toplam'] ?? '0')!,
    );
    
    // Kablo tesisatı fiyatını da ekle
    double kabloTesisatiFiyati = 0;
    if (kabloTesisatiAktif && kabloTesisatiUrunu != null) {
      kabloTesisatiFiyati = double.tryParse(kabloTesisatiUrunu!['toplam'] ?? '0') ?? 0;
    }
    
    return urunlerToplami + kabloTesisatiFiyati;
  }

  Future<void> pdfOlustur() async {
    // Zorunlu alanları kontrol et
    if (secilenCari == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cari seçimi zorunludur!')),
      );
      return;
    }

    if (teklifIcerigiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teklif içeriği alanı zorunludur!')),
      );
      return;
    }

    if (eklenenUrunler.isEmpty && !kabloTesisatiAktif) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir ürün eklemelisiniz!')),
      );
      return;
    }

    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = "${now.day}.${now.month}.${now.year}";

    // Firma Ünvanı cariden çekiliyor
    String firmaUnvani = '';
    if (secilenCari != null) {
      final cari = cariler.firstWhere(
        (c) => c['CariKodu'] == secilenCari,
        orElse: () => {'CariAdi': ''},
      );
      firmaUnvani = cari['CariAdi'] ?? '';
    }

    // Ek açıklama ve teklif içeriği
    String ekstraAciklama = ekstraAciklamaController.text.trim();
    String teklifIcerigi = teklifIcerigiController.text.trim();

    // Türkçe karakter desteği için Roboto fontu
    final font = await pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final fontBold = await pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );

    // Logo yükle
    pw.Widget? logoWidget;
    try {
      final logoBytes = await rootBundle.load('assets/logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      logoWidget = pw.Image(
        logoImage,
        height: 60,
        width: 160,
        fit: pw.BoxFit.contain,
      );
    } catch (e) {
      logoWidget = null;
    }

    // Ürün fotoğraflarını önceden yükle (hem dosya hem network)
    List<pw.Widget?> urunFotolari = [];
    for (final urun in eklenenUrunler) {
      pw.Widget? imageWidget;
      if (urun['imagePath'] != null &&
          urun['imagePath'].toString().isNotEmpty) {
        final path = urun['imagePath'].toString();
        if (File(path).existsSync()) {
          final imageBytes = File(path).readAsBytesSync();
          imageWidget = pw.Image(
            pw.MemoryImage(imageBytes),
            width: 40,
            height: 40,
            fit: pw.BoxFit.cover,
          );
        } else if (path.startsWith('http')) {
          try {
            final netBytes = await networkImage(path);
            imageWidget = pw.Image(
              netBytes,
              width: 40,
              height: 40,
              fit: pw.BoxFit.cover,
            );
          } catch (_) {}
        }
      }
      urunFotolari.add(imageWidget);
    }

    // Sayfa yönetimi için ürünleri böl
    List<List<Map<String, dynamic>>> sayfaUrunleri = [];
    List<Map<String, dynamic>> mevcutSayfa = [];
    
    // İlk sayfa için ürünleri böl (header ve footer için yer bırak)
    int maxUrunPerSayfa = 15; // İlk sayfa için maksimum ürün sayısı
    int urunSayisi = 0;
    
    for (final urun in eklenenUrunler) {
      mevcutSayfa.add(urun);
      urunSayisi++;
      
      if (urunSayisi >= maxUrunPerSayfa) {
        sayfaUrunleri.add(List.from(mevcutSayfa));
        mevcutSayfa.clear();
        urunSayisi = 0;
        maxUrunPerSayfa = 25; // Sonraki sayfalar için daha fazla ürün
      }
    }
    
    // Kalan ürünleri ekle
    if (mevcutSayfa.isNotEmpty) {
      sayfaUrunleri.add(mevcutSayfa);
    }
    
    // Kablo tesisatı varsa son sayfaya ekle
    if (kabloTesisatiAktif && kabloTesisatiUrunu != null) {
      if (sayfaUrunleri.isNotEmpty) {
        sayfaUrunleri.last.add(kabloTesisatiUrunu!);
      } else {
        sayfaUrunleri.add([kabloTesisatiUrunu!]);
      }
    }

    // İlk sayfa
    if (sayfaUrunleri.isNotEmpty) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo ve başlık
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (logoWidget != null) logoWidget,
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Tarih: $formattedDate',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                color: PdfColors.black,
                height: 2,
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'FİYAT TEKLİFİ',
                  style: pw.TextStyle(font: fontBold, fontSize: 18),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                color: PdfColors.black,
                height: 1,
              ),
              pw.SizedBox(height: 12),
              // Firma ve teklif bilgileri
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'FİRMA ÜNVANI: ',
                          style: pw.TextStyle(font: fontBold, fontSize: 11),
                        ),
                        pw.Text(
                          firmaUnvani,
                          style: pw.TextStyle(font: font, fontSize: 11),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'İLGİLİ KİŞİ: ',
                          style: pw.TextStyle(font: fontBold, fontSize: 11),
                        ),
                        pw.Text(
                          ilgiliKisiController.text.isNotEmpty
                              ? ilgiliKisiController.text
                              : '-',
                          style: pw.TextStyle(font: font, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TEKLİF İÇERİĞİ: ',
                          style: pw.TextStyle(font: fontBold, fontSize: 11),
                        ),
                        pw.Text(
                          teklifIcerigi,
                          style: pw.TextStyle(font: font, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                color: PdfColors.black,
                height: 1,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Firmamızdan talep ettiğiniz ürünlere ait detay bilgiler ve fiyatlar aşağıda bilginize sunulmuştur',
                style: pw.TextStyle(font: font, fontSize: 11),
              ),
              pw.SizedBox(height: 8),
                // Tablo başlığı
              pw.Table(
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColors.black),
                    verticalInside: pw.BorderSide.none,
                    left: pw.BorderSide.none,
                    right: pw.BorderSide.none,
                    top: pw.BorderSide.none,
                    bottom: pw.BorderSide.none,
                  ),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'FOTO',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'AÇIKLAMA',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'MİKTAR',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'BİRİM FİYAT',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'TUTAR',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
                // İlk sayfa ürünleri
                pw.Table(
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColors.black),
                    verticalInside: pw.BorderSide.none,
                    left: pw.BorderSide.none,
                    right: pw.BorderSide.none,
                    top: pw.BorderSide.none,
                    bottom: pw.BorderSide.none,
                  ),
                  children: sayfaUrunleri[0].asMap().entries.map((entry) {
                    final urun = entry.value;
                    // urunFotolari'na global index ile eriş
                    int globalIndex = eklenenUrunler.indexOf(urun);
                    final imageWidget = globalIndex != -1 ? urunFotolari[globalIndex] : null;
                    return pw.TableRow(
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(2),
                          child:
                              imageWidget ??
                              pw.Text(
                                '📷',
                                style: pw.TextStyle(font: font, fontSize: 16),
                              ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                urun['stokAdi'],
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if ((urun['aciklama'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                pw.Text(
                                  urun['aciklama'],
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            urun['miktar'],
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            urun['brutFiyat'],
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            urun['toplam'],
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                // Eğer sadece bir sayfa varsa toplam ve footer ekle
                if (sayfaUrunleri.length == 1) ...[
                  pw.SizedBox(height: 8),
                  // Ara toplam ve ek açıklama
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Container()),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Text(
                                'ARA TOPLAM:',
                                style: pw.TextStyle(font: fontBold, fontSize: 11),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                '${genelToplam().toStringAsFixed(2)} ₺',
                                style: pw.TextStyle(font: font, fontSize: 11),
                              ),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Text(
                                ekstraAciklama.isNotEmpty
                                    ? ekstraAciklama
                                    : '',
                                style: pw.TextStyle(font: fontBold, fontSize: 11),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                ekstraAciklama.isNotEmpty ? '-' : '',
                                style: pw.TextStyle(font: font, fontSize: 11),
                              ),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Text(
                                'GENEL TOPLAM:',
                                style: pw.TextStyle(font: fontBold, fontSize: 12),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                '${genelToplam().toStringAsFixed(2)} ₺',
                                style: pw.TextStyle(font: fontBold, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  // Teklif genel koşulları
                  pw.Text(
                    'Teklif Genel Koşulları',
                    style: pw.TextStyle(font: fontBold, fontSize: 11),
                  ),
                  pw.Bullet(
                    text:
                        'Ödeme Şekli: Ödeme teklif onayı ile birlikte nakit/havale veya kredi kartı olarak tahsil edilecektir',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.red,
                    ),
                  ),
                  pw.Bullet(
                    text:
                        'Masraflar: Kargo, kurulum giderleri müşteriye aittir. Tarafımızdan ödendiği durumda müşteriye fatura edilecektir.',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.red,
                    ),
                  ),
                  pw.Bullet(
                    text:
                        'Teklif Onay: Teklifimizin işleme alınabilmesi için teklif formuna kaşe ve imza eklenerek tarafımıza iletilmesi gerekmektedir.',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.red,
                    ),
                  ),
                  pw.Bullet(
                    text:
                        'Fiyatlarımızı ve ürünleri değerlendirdiğiniz için, belirtilen miktarlar veya ürünlerde herhangi bir değişiklik olması durumunda, verilen teklif geçersiz olur ve teklif yeniden fiyatlandırılacaktır.',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.red,
                    ),
                  ),
                  pw.Bullet(
                    text: 'Fiyat teklifimiz verildiği günden itibaren 7 gündür.',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.red,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Teklifimizin olumlu karşılanacağını ümit eder, çalışmalarınızda başarılar dileriz.',
                    style: pw.TextStyle(font: font, fontSize: 11),
                  ),
                  pw.SizedBox(height: 16),
                  // İmza alanları
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.black),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Container(
                            height: 40,
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              'SATIŞ SORUMLUSU',
                              style: pw.TextStyle(font: font, fontSize: 10),
                            ),
                          ),
                          pw.Container(
                            height: 40,
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              'YETKİLİ ONAY',
                              style: pw.TextStyle(font: font, fontSize: 10),
                            ),
                          ),
                          pw.Container(
                            height: 40,
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              'FİRMA ONAYI-KAŞE/İMZA',
                              style: pw.TextStyle(font: font, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  // Alt iletişim bilgileri
                  pw.Text(
                    'TEL: 0554 644 52 24   E-MAIL: info@analizotomasyon.com',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.Text(
                    'Mücahitler Mah. Gazi Muhtar Paşa Bulv. 10031 Nolu Sokak No:42 Yaşam İş Merk. Kat:7 No:708 Şehitkamil/Gaziantep',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ],
            );
          },
        ),
      );
    }

    // Ek sayfalar (varsa)
    for (int i = 1; i < sayfaUrunleri.length; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Tablo devamı
                pw.Table(
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColors.black),
                    verticalInside: pw.BorderSide.none,
                    left: pw.BorderSide.none,
                    right: pw.BorderSide.none,
                    top: pw.BorderSide.none,
                    bottom: pw.BorderSide.none,
                  ),
                  children: sayfaUrunleri[i].asMap().entries.map((entry) {
                    final urun = entry.value;
                    // urunFotolari'na global index ile eriş
                    int globalIndex = eklenenUrunler.indexOf(urun);
                    final imageWidget = globalIndex != -1 ? urunFotolari[globalIndex] : null;
                    return pw.TableRow(
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(2),
                          child:
                              imageWidget ??
                              pw.Text(
                                '📷',
                                style: pw.TextStyle(font: font, fontSize: 16),
                              ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                urun['stokAdi'],
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if ((urun['aciklama'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                pw.Text(
                                  urun['aciklama'],
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            urun['miktar'],
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            urun['brutFiyat'],
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            urun['toplam'],
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                // Son sayfa ise toplam ve footer ekle
                if (i == sayfaUrunleri.length - 1) ...[
              pw.SizedBox(height: 8),
              // Ara toplam ve ek açıklama
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Container()),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'ARA TOPLAM:',
                            style: pw.TextStyle(font: fontBold, fontSize: 11),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            '${genelToplam().toStringAsFixed(2)} ₺',
                            style: pw.TextStyle(font: font, fontSize: 11),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            ekstraAciklama.isNotEmpty
                                ? ekstraAciklama
                                    : '',
                            style: pw.TextStyle(font: fontBold, fontSize: 11),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                                ekstraAciklama.isNotEmpty ? '-' : '',
                            style: pw.TextStyle(font: font, fontSize: 11),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'GENEL TOPLAM:',
                            style: pw.TextStyle(font: fontBold, fontSize: 12),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            '${genelToplam().toStringAsFixed(2)} ₺',
                            style: pw.TextStyle(font: fontBold, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              // Teklif genel koşulları
              pw.Text(
                'Teklif Genel Koşulları',
                style: pw.TextStyle(font: fontBold, fontSize: 11),
              ),
              pw.Bullet(
                text:
                    'Ödeme Şekli: Ödeme teklif onayı ile birlikte nakit/havale veya kredi kartı olarak tahsil edilecektir',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.red,
                ),
              ),
              pw.Bullet(
                text:
                    'Masraflar: Kargo, kurulum giderleri müşteriye aittir. Tarafımızdan ödendiği durumda müşteriye fatura edilecektir.',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.red,
                ),
              ),
              pw.Bullet(
                text:
                    'Teklif Onay: Teklifimizin işleme alınabilmesi için teklif formuna kaşe ve imza eklenerek tarafımıza iletilmesi gerekmektedir.',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.red,
                ),
              ),
              pw.Bullet(
                text:
                    'Fiyatlarımızı ve ürünleri değerlendirdiğiniz için, belirtilen miktarlar veya ürünlerde herhangi bir değişiklik olması durumunda, verilen teklif geçersiz olur ve teklif yeniden fiyatlandırılacaktır.',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.red,
                ),
              ),
              pw.Bullet(
                text: 'Fiyat teklifimiz verildiği günden itibaren 7 gündür.',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.red,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Teklifimizin olumlu karşılanacağını ümit eder, çalışmalarınızda başarılar dileriz.',
                style: pw.TextStyle(font: font, fontSize: 11),
              ),
              pw.SizedBox(height: 16),
              // İmza alanları
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        height: 40,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'SATIŞ SORUMLUSU',
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ),
                      pw.Container(
                        height: 40,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'YETKİLİ ONAY',
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ),
                      pw.Container(
                        height: 40,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'FİRMA ONAYI-KAŞE/İMZA',
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              // Alt iletişim bilgileri
              pw.Text(
                'TEL: 0554 644 52 24   E-MAIL: info@analizotomasyon.com',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                'Mücahitler Mah. Gazi Muhtar Paşa Bulv. 10031 Nolu Sokak No:42 Yaşam İş Merk. Kat:7 No:708 Şehitkamil/Gaziantep',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
                ],
            ],
          );
        },
      ),
    );
    }

    final output = Directory('/storage/emulated/0/Download');
    final filePath =
        '${output.path}/teklif_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);

    // PDF'yi kaydet
    await file.writeAsBytes(await pdf.save());

    // PDF'yi sunucuya yükle
    await uploadPdf(file);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool isRequired = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.deepPurple.shade400, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.deepPurple.shade400,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String displayKey,
    required String valueKey,
    required Function(String?) onChanged,
    required IconData icon,
    bool isRequired = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.deepPurple.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item[valueKey],
                  child: Text(
                    item[displayKey],
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              dropdownColor: Colors.white,
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.deepPurple.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> urun, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _slideAnimation.value.dy)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  urun['stokAdi'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip('Miktar', urun['miktar']),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoChip(
                            'Fiyat',
                            '${urun['brutFiyat']} ₺',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            'İskonto1',
                            '%${urun['iskonto1']}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoChip(
                            'İskonto2',
                            '${urun['iskonto2']} ₺',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip('KDV', '%${urun['kdv']}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoChip(
                            'Toplam',
                            '${urun['toplam']} ₺',
                            isTotal: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      eklenenUrunler.removeAt(index);
                    });
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isTotal ? Colors.green.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTotal ? Colors.green.shade300 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isTotal ? Colors.green.shade700 : Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green.shade800 : Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50,
              Colors.deepPurple.shade100,
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
                    colors: [
                      Colors.deepPurple.shade600,
                      Colors.deepPurple.shade400,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
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
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Teklif Oluştur',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: eklenenUrunler.isNotEmpty ? pdfOlustur : null,
                      tooltip: 'PDF Oluştur',
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - _slideAnimation.value.dy)),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Form Section
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.add_shopping_cart,
                                          color: Colors.deepPurple.shade400,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Ürün Bilgileri',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    _buildDropdownField(
                                      label: 'Cari Seçin',
                                      value: secilenCari,
                                      items: cariler,
                                      displayKey: 'CariAdi',
                                      valueKey: 'CariKodu',
                                      onChanged: (value) {
                                        setState(() {
                                          secilenCari = value;
                                        });
                                      },
                                      icon: Icons.person,
                                      isRequired: true,
                                    ),

                                    _buildInputField(
                                      label: 'İlgili Kişi',
                                      controller: ilgiliKisiController,
                                      icon: Icons.contact_phone,
                                      keyboardType: TextInputType.text,
                                    ),

                                    _buildDropdownField(
                                      label: 'Ürün Seçin',
                                      value: secilenUrun,
                                      items: urunler,
                                      displayKey: 'StokAdi',
                                      valueKey: 'StokKodu',
                                      onChanged: (value) {
                                        setState(() {
                                          secilenUrun = value;
                                        });
                                      },
                                      icon: Icons.inventory,
                                      isRequired: true,
                                    ),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'Miktar',
                                            controller: miktarController,
                                            icon: Icons.scale,
                                            keyboardType: TextInputType.number,
                                            isRequired: true,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'Brüt Fiyat',
                                            controller: brutFiyatController,
                                            icon: Icons.attach_money,
                                            keyboardType: TextInputType.number,
                                            isRequired: true,
                                          ),
                                        ),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'İskonto1 (%)',
                                            controller: iskonto1Controller,
                                            icon: Icons.discount,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'İskonto2 (₺)',
                                            controller: iskonto2Controller,
                                            icon: Icons.discount,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),

                                    _buildInputField(
                                      label: 'KDV (%)',
                                      controller: kdvController,
                                      icon: Icons.receipt,
                                      keyboardType: TextInputType.number,
                                    ),

                                    _buildInputField(
                                      label: 'Teklif İçeriği',
                                      controller: teklifIcerigiController,
                                      icon: Icons.description,
                                      keyboardType: TextInputType.text,
                                      isRequired: true,
                                    ),

                                    // Kablo tesisatı aktivasyon alanı
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.build,
                                                color: Colors.deepPurple.shade400,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                          'Kablo Tesisatı, Montaj, Aktivasyon, Kurulum',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                              Switch(
                                                value: kabloTesisatiAktif,
                                                onChanged: _onKabloTesisatiToggle,
                                                activeColor: Colors.deepPurple.shade400,
                                              ),
                                            ],
                                          ),
                                          if (kabloTesisatiAktif) ...[
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: kabloTesisatiFiyatController,
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 16),
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.grey.shade50,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Colors.deepPurple.shade400,
                                                    width: 2,
                                                  ),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                hintText: 'Fiyat giriniz',
                                                prefixIcon: Icon(
                                                  Icons.attach_money,
                                                  color: Colors.deepPurple.shade400,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    _buildInputField(
                                      label: 'Ekstra Açıklama',
                                      controller: ekstraAciklamaController,
                                      icon: Icons.note_add,
                                      keyboardType: TextInputType.text,
                                    ),

                                    // Fotoğraf seçme alanı
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.photo_camera,
                                                color:
                                                    Colors.deepPurple.shade400,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Ürün Fotoğrafı',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: _selectedImage != null
                                                ? Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        child: Image.file(
                                                          _selectedImage!,
                                                          width:
                                                              double.infinity,
                                                          height:
                                                              double.infinity,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 8,
                                                        right: 8,
                                                        child: GestureDetector(
                                                          onTap: _removeImage,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  4,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .red,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                ),
                                                            child: const Icon(
                                                              Icons.close,
                                                              color:
                                                                  Colors.white,
                                                              size: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : GestureDetector(
                                                    onTap: _pickImage,
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .add_photo_alternate,
                                                            size: 40,
                                                            color: Colors
                                                                .grey
                                                                .shade400,
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            'Fotoğraf Seç',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                              fontSize: 14,
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

                                    const SizedBox(height: 24),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 56,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.deepPurple.shade600,
                                                foregroundColor: Colors.white,
                                                elevation: 8,
                                                shadowColor: Colors.deepPurple
                                                    .withOpacity(0.4),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                textStyle: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onPressed: urunEkle,
                                              icon: const Icon(Icons.add),
                                              label: const Text('Ürün Ekle'),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        SizedBox(
                                          height: 56,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green.shade600,
                                              foregroundColor: Colors.white,
                                              elevation: 8,
                                              shadowColor: Colors.green
                                                  .withOpacity(0.4),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            onPressed: eklenenUrunler.isNotEmpty
                                                ? pdfOlustur
                                                : null,
                                            icon: const Icon(
                                              Icons.picture_as_pdf,
                                            ),
                                            label: const Text('PDF'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Products List
                              if (eklenenUrunler.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.list,
                                      color: Colors.deepPurple.shade400,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Eklenen Ürünler',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                ...eklenenUrunler.asMap().entries.map((entry) {
                                  return _buildProductCard(
                                    entry.value,
                                    entry.key,
                                  );
                                }).toList(),

                                // Kablo tesisatı ürününü göster (eğer aktifse)
                                if (kabloTesisatiAktif && kabloTesisatiUrunu != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Colors.orange.shade50, Colors.orange.shade100],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.build,
                                          color: Colors.orange,
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        kabloTesisatiUrunu!['stokAdi'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildInfoChip(
                                                  'Fiyat',
                                                  '${kabloTesisatiUrunu!['brutFiyat']} ₺',
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: _buildInfoChip(
                                                  'Toplam',
                                                  '${kabloTesisatiUrunu!['toplam']} ₺',
                                                  isTotal: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            kabloTesisatiAktif = false;
                                            kabloTesisatiUrunu = null;
                                            kabloTesisatiFiyatController.clear();
                                          });
                                        },
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 24),

                                // Total Section
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.green.shade100,
                                        Colors.green.shade50,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'GENEL TOPLAM:',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          Text(
                                            '${genelToplam().toStringAsFixed(2)} ₺',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade600,
                                            foregroundColor: Colors.white,
                                            elevation: 8,
                                            shadowColor: Colors.green
                                                .withOpacity(0.4),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onPressed: pdfOlustur,
                                          icon: const Icon(
                                            Icons.picture_as_pdf,
                                          ),
                                          label: const Text(
                                            'PDF Oluştur ve Yazdır',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
