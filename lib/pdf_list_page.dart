import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';

class PdfListPage extends StatefulWidget {
  const PdfListPage({Key? key}) : super(key: key);

  @override
  _PdfListPageState createState() => _PdfListPageState();
}

class _PdfListPageState extends State<PdfListPage> {
  List<dynamic> pdfFiles = [];
  List<dynamic> filteredPdfFiles = [];
  bool isLoading = true;
  String? errorMessage;
  int selectedFilterIndex = 0;
  bool sortAscending = true;
  bool showSearch = false;

  TextEditingController searchController = TextEditingController();
  final GlobalKey _searchKey = GlobalKey();

  final String baseUrl = 'http://10.0.2.2:5000';
  final List<String> filterLabels = ['Açık', 'Kapalı'];

  @override
  void initState() {
    super.initState();
    fetchPdfList();
  }

  Future<void> fetchPdfList() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final apiUrl =
        '$baseUrl/pdf/list?kilitli=${selectedFilterIndex == 1 ? '1' : '0'}';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          pdfFiles = data;
          isLoading = false;
          errorMessage = null;
        });
        applySortingAndFilter();
      } else {
        setState(() {
          errorMessage =
              'Sunucudan PDF listesi alınamadı. (Kod: ${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Hata oluştu: $e';
        isLoading = false;
      });
    }
  }

  void applySortingAndFilter() {
    List<dynamic> tempList = [...pdfFiles];

    String keyword = searchController.text.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      tempList = tempList.where((pdf) {
        final name = (pdf['teklif_ismi'] ?? '').toLowerCase();
        final desc = (pdf['teklif_aciklama'] ?? '').toLowerCase();
        return name.contains(keyword) || desc.contains(keyword);
      }).toList();
    }

    tempList.sort((a, b) {
      DateTime dateA =
          DateTime.tryParse(a['teklif_create_date'] ?? '') ?? DateTime(2000);
      DateTime dateB =
          DateTime.tryParse(b['teklif_create_date'] ?? '') ?? DateTime(2000);
      return sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    setState(() {
      filteredPdfFiles = tempList;
    });
  }

  Future<String?> downloadAndSavePdf(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);
      if (file.existsSync()) {
        return filePath;
      }

      final url = '$baseUrl/pdf/download/$fileName';
      await Dio().download(url, filePath);
      return filePath;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dosya indirilemedi: $e')));
      return null;
    }
  }

  Future<void> toggleLockPdf(String fileName, bool currentlyLocked) async {
    final endpoint = currentlyLocked ? '/pdf/unlock' : '/pdf/lock';

    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"filename": fileName}),
    );

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlyLocked ? 'PDF açığa alındı' : 'PDF kapalıya alındı',
            ),
          ),
        );
        fetchPdfList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız: ${res['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sunucu hatası: ${response.statusCode}')),
      );
    }
  }

  Future<void> deletePdf(String fileName) async {
    final url = Uri.parse('$baseUrl/pdf/delete');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"filename": fileName}),
    );

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      if (res['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF silindi')));
        fetchPdfList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız: ${res['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sunucu hatası: ${response.statusCode}')),
      );
    }
  }

  void openPdf(String filePath) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: filePath)),
    );
  }

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Dosyaları'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                showSearch = !showSearch;
                if (!showSearch) searchController.clear();
                applySortingAndFilter();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          ToggleButtons(
            isSelected: List.generate(
              filterLabels.length,
              (index) => index == selectedFilterIndex,
            ),
            onPressed: (index) {
              setState(() {
                selectedFilterIndex = index;
                fetchPdfList();
              });
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: Theme.of(context).primaryColor,
            children: filterLabels
                .map(
                  (label) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Text(label, style: const TextStyle(fontSize: 16)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1.0,
                child: child,
              );
            },
            child: showSearch
                ? Padding(
                    key: _searchKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'Başlıkta veya isimde ara...',
                              suffixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (val) => applySortingAndFilter(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(
                            sortAscending
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                          ),
                          tooltip: sortAscending
                              ? 'Yeniden eskiye sırala'
                              : 'Eskiden yeniye sırala',
                          onPressed: () {
                            setState(() {
                              sortAscending = !sortAscending;
                              applySortingAndFilter();
                            });
                          },
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : filteredPdfFiles.isEmpty
                  ? Text(
                      selectedFilterIndex == 1
                          ? 'Kapalı Teklif Bulunamadı...'
                          : 'Açık Teklif Bulunamadı...',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: filteredPdfFiles.length,
                      itemBuilder: (context, index) {
                        final pdf = filteredPdfFiles[index];
                        final fileName = pdf['teklif_ismi'] ?? '';
                        final title = pdf['teklif_aciklama'] ?? 'Başlık yok';
                        final date = pdf['teklif_create_date'] ?? '';
                        final locked = pdf['teklif_kilitli'] ?? false;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.redAccent,
                              size: 40,
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text('Oluşturulma: ${formatDate(date)}'),
                            onTap: () async {
                              final filePath = await downloadAndSavePdf(
                                fileName,
                              );
                              if (filePath != null) {
                                openPdf(filePath);
                              }
                            },
                            trailing: SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      locked ? Icons.undo : Icons.check,
                                      color: locked
                                          ? Colors.orange
                                          : Colors.green[600],
                                    ),
                                    onPressed: () {
                                      toggleLockPdf(fileName, locked);
                                    },
                                    tooltip: locked
                                        ? 'Açığa Al'
                                        : 'Kapalıya Al',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Silme Onayı'),
                                          content: const Text(
                                            'Bu PDF dosyasını silmek istediğinize emin misiniz?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: const Text('İptal'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(ctx).pop();
                                                deletePdf(fileName);
                                              },
                                              child: const Text('Sil'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    tooltip: 'Sil',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  const PdfViewerPage({Key? key, required this.filePath}) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PDFViewController _pdfViewController;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sayfa ${_currentPage + 1} / $_totalPages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () {
                    _pdfViewController.setPage(_currentPage - 1);
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage + 1 < _totalPages
                ? () {
                    _pdfViewController.setPage(_currentPage + 1);
                  }
                : null,
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            onRender: (_pages) {
              setState(() {
                _totalPages = _pages!;
                _isReady = true;
              });
            },
            onViewCreated: (PDFViewController vc) {
              _pdfViewController = vc;
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page ?? 0;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              debugPrint(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = 'Sayfa hatası: $page - $error';
              });
              debugPrint('$page: $error');
            },
          ),
          if (!_isReady) const Center(child: CircularProgressIndicator()),
          if (errorMessage.isNotEmpty)
            Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
