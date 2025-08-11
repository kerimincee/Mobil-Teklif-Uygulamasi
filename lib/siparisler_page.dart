import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CariDetayPage extends StatefulWidget {
  final String cariKodu;

  const CariDetayPage({super.key, required this.cariKodu});

  @override
  State<CariDetayPage> createState() => _CariDetayPageState();
}

class _CariDetayPageState extends State<CariDetayPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<String> _titles = ['Siparişler', 'Risk Bilgileri'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_titles[_currentPage]} - ${widget.cariKodu}'),
      ),
      body: PageView(
        controller: _controller,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          SiparislerContent(cariKodu: widget.cariKodu),
          RiskContent(cariKodu: widget.cariKodu),
        ],
      ),
    );
  }
}

class SiparislerContent extends StatefulWidget {
  final String cariKodu;

  const SiparislerContent({super.key, required this.cariKodu});

  @override
  State<SiparislerContent> createState() => _SiparislerContentState();
}

class _SiparislerContentState extends State<SiparislerContent>
    with SingleTickerProviderStateMixin {
  List<dynamic> siparisler = [];
  bool isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    fetchSiparisler();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> fetchSiparisler() async {
    final url = Uri.parse(
      'http://172.20.10.3:5000/cariler/${widget.cariKodu}/siparisler',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          siparisler = jsonDecode(response.body);
          isLoading = false;
        });
        _animController.forward();
      } else {
        setState(() {
          siparisler = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        siparisler = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Siparişler yükleniyor...',
              style: TextStyle(color: Colors.teal.shade700),
            ),
          ],
        ),
      );
    }

    if (siparisler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Sipariş bulunamadı.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: siparisler.length,
          itemBuilder: (context, index) {
            final s = siparisler[index];
            final evrakTip = s["EvrakTip"]?.toString() ?? "-";
            final evrakNoSeri = s["EvrakNoSeri"]?.toString() ?? "";
            final evrakNoSira = s["EvrakNoSira"]?.toString() ?? "";
            final tarih = s["Tarih"]?.toString() ?? "";
            final tutarRaw = s["Tutar"];
            double tutar = 0.0;

            if (tutarRaw is int) {
              tutar = tutarRaw.toDouble();
            } else if (tutarRaw is double) {
              tutar = tutarRaw;
            } else {
              tutar = double.tryParse(tutarRaw.toString()) ?? 0.0;
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
                title: Text(
                  evrakTip,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.confirmation_num,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'No: $evrakNoSeri$evrakNoSira',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tarih,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tutar.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RiskContent extends StatefulWidget {
  final String cariKodu;

  const RiskContent({super.key, required this.cariKodu});

  @override
  State<RiskContent> createState() => _RiskContentState();
}

class _RiskContentState extends State<RiskContent> {
  Map<String, dynamic>? riskData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRisk();
  }

  Future<void> fetchRisk() async {
    final url = Uri.parse(
      'http://10.0.2.2:5000/cariler/${widget.cariKodu}/risk',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          riskData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          riskData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        riskData = null;
        isLoading = false;
      });
    }
  }

  String getStringFromRiskData(String key) {
    if (riskData == null) return '';
    final val = riskData![key];
    if (val == null) return '';
    return val.toString();
  }

  double getDoubleFromRiskData(String key) {
    if (riskData == null) return 0;
    final val = riskData![key];
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  Widget _buildRiskInfoCard({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
    Widget? badge,
    double? numericValue,
  }) {
    Color valueColor = Colors.black87;
    if (numericValue != null) {
      if (numericValue < 0) {
        valueColor = Colors.red;
      } else if (numericValue > 0) {
        valueColor = Colors.green;
      } else {
        valueColor = Colors.orange;
      }
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.blue).withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color ?? Colors.blue, size: 28),
          if (badge != null) ...[const SizedBox(width: 8), badge],
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color ?? Colors.blue,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSummaryBox(
    double toplamRisk,
    double bakiye,
    double toplamKredi,
    double cekRisk,
  ) {
    Color colorFor(double v) {
      if (v < 0) return Colors.red;
      if (v > 0) return Colors.green;
      return Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Bakiye',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bakiye.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorFor(bakiye),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Toplam Kredi',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    toplamKredi.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorFor(toplamKredi),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Çek Risk',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cekRisk.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorFor(cekRisk),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const Text(
                    'Toplam Risk',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    toplamRisk.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: colorFor(toplamRisk),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> buildPagedRiskCards(List<Widget> cards) {
      List<Widget> pages = [];
      for (int i = 0; i < cards.length; i += 4) {
        final pageCards = cards
            .sublist(i, (i + 4 > cards.length) ? cards.length : i + 4)
            .map((card) => Expanded(child: card))
            .toList();
        // Son sayfada 4'ten az kart varsa, boş Expanded ekle
        while (pageCards.length < 4) {
          pageCards.add(const Expanded(child: SizedBox()));
        }
        pages.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: pageCards,
            ),
          ),
        );
      }
      return pages;
    }

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Risk bilgileri yükleniyor...',
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ],
        ),
      );
    }

    final labels = [
      'Cari Kodu',
      'Cari Ünvan',
      'Bakiye',
      'Bu Yıl Cirosu',
      'Geçen Yıl Cirosu',
      'Çek Risk',
      'Bakiye Risk',
      'Toplam Risk',
      'Toplam Kredi',
    ];
    final icons = [
      Icons.code,
      Icons.business,
      Icons.account_balance_wallet,
      Icons.trending_up,
      Icons.trending_down,
      Icons.assignment,
      Icons.warning,
      Icons.shield,
      Icons.credit_score,
    ];
    final colors = [
      Colors.blue,
      Colors.indigo,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.deepOrange,
      Colors.teal,
      Colors.brown,
    ];

    if (riskData == null) {
      final emptyCards = List.generate(labels.length, (index) {
        return _buildRiskInfoCard(
          label: labels[index],
          value: '',
          icon: icons[index],
          color: colors[index],
        );
      });
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SizedBox(height: 18),
          SizedBox(
            height: 4 * 110.0 + 32, // 4 kart yüksekliği + boşluk
            child: PageView(
              scrollDirection: Axis.horizontal,
              children: buildPagedRiskCards(emptyCards),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Cari Risk Özeti',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 18),
          _buildRiskSummaryBox(0, 0, 0, 0),
        ],
      );
    }

    final double bakiye = getDoubleFromRiskData("Bakiye");
    final double toplamRisk = getDoubleFromRiskData("ToplamRisk");
    final double toplamKredi = getDoubleFromRiskData("ToplamKredi");
    final double cekRisk = getDoubleFromRiskData("CekRisk");
    Widget? bakiyeBadge;
    if (bakiye < 0) {
      bakiyeBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Borçlu',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    } else if (bakiye > 0) {
      bakiyeBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Alacaklı',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    final riskCards = [
      _buildRiskInfoCard(
        label: 'Cari Kodu',
        value: getStringFromRiskData("CariKodu"),
        icon: Icons.code,
        color: Colors.blue,
      ),
      _buildRiskInfoCard(
        label: 'Cari Ünvan',
        value: getStringFromRiskData("CariUnvan"),
        icon: Icons.business,
        color: Colors.indigo,
      ),
      _buildRiskInfoCard(
        label: 'Bakiye',
        value: bakiye.toStringAsFixed(2),
        icon: Icons.account_balance_wallet,
        color: bakiye < 0
            ? Colors.red
            : (bakiye > 0 ? Colors.green : Colors.orange),
        badge: bakiyeBadge,
        numericValue: bakiye,
      ),
      _buildRiskInfoCard(
        label: 'Bu Yıl Cirosu',
        value: getDoubleFromRiskData("BuYilCirosu").toStringAsFixed(2),
        icon: Icons.trending_up,
        color: Colors.green,
        numericValue: getDoubleFromRiskData("BuYilCirosu"),
      ),
      _buildRiskInfoCard(
        label: 'Geçen Yıl Cirosu',
        value: getDoubleFromRiskData("GecenYilCirosu").toStringAsFixed(2),
        icon: Icons.trending_down,
        color: Colors.red,
        numericValue: getDoubleFromRiskData("GecenYilCirosu"),
      ),
      _buildRiskInfoCard(
        label: 'Çek Risk',
        value: cekRisk.toStringAsFixed(2),
        icon: Icons.assignment,
        color: Colors.purple,
        numericValue: cekRisk,
      ),
      _buildRiskInfoCard(
        label: 'Bakiye Risk',
        value: getDoubleFromRiskData("BakiyeRisk").toStringAsFixed(2),
        icon: Icons.warning,
        color: Colors.deepOrange,
        numericValue: getDoubleFromRiskData("BakiyeRisk"),
      ),
      _buildRiskInfoCard(
        label: 'Toplam Risk',
        value: toplamRisk.toStringAsFixed(2),
        icon: Icons.shield,
        color: Colors.teal,
        numericValue: toplamRisk,
      ),
      _buildRiskInfoCard(
        label: 'Toplam Kredi',
        value: toplamKredi.toStringAsFixed(2),
        icon: Icons.credit_score,
        color: Colors.brown,
        numericValue: toplamKredi,
      ),
    ];

    final pagedRiskCards = buildPagedRiskCards(riskCards);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 18),
        SizedBox(
          height: 4 * 110.0 + 32, // 4 kart yüksekliği + boşluk
          child: PageView(
            scrollDirection: Axis.horizontal,
            children: pagedRiskCards,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Cari Risk Özeti',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 18),
        _buildRiskSummaryBox(toplamRisk, bakiye, toplamKredi, cekRisk),
      ],
    );
  }
}
