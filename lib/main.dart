import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAdXzXJ1PmmBjmWLYBjTk1uohNa-4YNn44",
      projectId: "presensi2-fahri",
      storageBucket: "presensi2-fahri.firebasestorage.app",
      messagingSenderId: "1071087435629",
      appId: "1:1071087435629:web:6fdf53c9dbe7eb82e92464",
    ),
  );
  runApp(const PresensiApp());
}

// ─── Firestore Service ────────────────────────────────────────────────────────

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'presensi';

  static Future<PresensiRecord?> cariHariIni(String nama) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap =
        await _db.collection(_col).where('nama', isEqualTo: nama).get();

    final filtered = snap.docs
        .map(PresensiRecord.fromFirestore)
        .where((r) =>
            r.tanggal.isAfter(startOfDay) && r.tanggal.isBefore(endOfDay))
        .toList();

    return filtered.isNotEmpty ? filtered.first : null;
  }

  static Future<PresensiRecord> absenMasuk(String nama, String status) async {
    final now = DateTime.now();
    final docRef = await _db.collection(_col).add({
      'nama': nama,
      'tanggal': Timestamp.fromDate(now),
      'jamMasuk': Timestamp.fromDate(now),
      'jamKeluar': null,
      'status': status,
    });
    return PresensiRecord(
      id: docRef.id,
      nama: nama,
      tanggal: now,
      jamMasuk: now,
      status: status,
    );
  }

  static Future<PresensiRecord> absenKeluar(PresensiRecord record) async {
    final now = DateTime.now();
    await _db.collection(_col).doc(record.id).update({
      'jamKeluar': Timestamp.fromDate(now),
    });
    return record.copyWith(jamKeluar: now);
  }

  static Stream<List<PresensiRecord>> streamHariIni() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection(_col)
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(PresensiRecord.fromFirestore)
            .where((r) =>
                r.tanggal.isAfter(startOfDay) && r.tanggal.isBefore(endOfDay))
            .toList());
  }

  static Stream<List<PresensiRecord>> streamSemua() {
    return _db
        .collection(_col)
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PresensiRecord.fromFirestore).toList());
  }
}

// ─── Models ──────────────────────────────────────────────────────────────────

class PresensiRecord {
  final String id;
  final String nama;
  final DateTime tanggal;
  final DateTime? jamMasuk;
  final DateTime? jamKeluar;
  final String status;

  PresensiRecord({
    required this.id,
    required this.nama,
    required this.tanggal,
    this.jamMasuk,
    this.jamKeluar,
    required this.status,
  });

  factory PresensiRecord.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PresensiRecord(
      id: doc.id,
      nama: d['nama'] ?? '',
      tanggal: (d['tanggal'] as Timestamp).toDate(),
      jamMasuk:
          d['jamMasuk'] != null ? (d['jamMasuk'] as Timestamp).toDate() : null,
      jamKeluar: d['jamKeluar'] != null
          ? (d['jamKeluar'] as Timestamp).toDate()
          : null,
      status: d['status'] ?? '',
    );
  }

  PresensiRecord copyWith({DateTime? jamKeluar}) {
    return PresensiRecord(
      id: id,
      nama: nama,
      tanggal: tanggal,
      jamMasuk: jamMasuk,
      jamKeluar: jamKeluar ?? this.jamKeluar,
      status: status,
    );
  }
}

// ─── App ──────────────────────────────────────────────────────────────────────

class PresensiApp extends StatelessWidget {
  const PresensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistem Presensi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A56DB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeSelector(),
    );
  }
}

// ─── Home Selector ────────────────────────────────────────────────────────────

class HomeSelector extends StatefulWidget {
  const HomeSelector({super.key});

  @override
  State<HomeSelector> createState() => _HomeSelectorState();
}

class _HomeSelectorState extends State<HomeSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _timer.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A56DB), Color(0xFF0E3A8C)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.fingerprint,
                        size: 46, color: Color(0xFF1A56DB)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SISTEM PRESENSI',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_pad(_now.hour)}:${_pad(_now.minute)}:${_pad(_now.second)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(_formatTanggal(_now),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 48),
                  _ModeButton(
                    icon: Icons.how_to_reg,
                    label: 'Presensi Mandiri',
                    subtitle: 'Ketik nama & absen sendiri',
                    color: Colors.white,
                    textColor: const Color(0xFF1A56DB),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PresensiMandiriPage()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ModeButton(
                    icon: Icons.admin_panel_settings,
                    label: 'Panel Admin',
                    subtitle: 'Login untuk kelola presensi',
                    color: Colors.white.withValues(alpha: 0.24),
                    textColor: Colors.white,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                  ),
                  const SizedBox(height: 32),
                  StreamBuilder<List<PresensiRecord>>(
                    stream: FirestoreService.streamHariIni(),
                    builder: (ctx, snap) {
                      final count = snap.data?.length ?? 0;
                      return Text(
                        'Total presensi hari ini: $count orang',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white30),
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 12)),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios,
                  color: textColor.withValues(alpha: 0.6), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Presensi Mandiri Page ────────────────────────────────────────────────────

class PresensiMandiriPage extends StatefulWidget {
  const PresensiMandiriPage({super.key});

  @override
  State<PresensiMandiriPage> createState() => _PresensiMandiriPageState();
}

class _PresensiMandiriPageState extends State<PresensiMandiriPage> {
  final _namaCtrl = TextEditingController();
  PresensiRecord? _presensiDitemukan;
  bool _dicari = false;
  bool _loading = false;
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    _namaCtrl.dispose();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  Future<void> _cariPresensi() async {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) return;
    setState(() => _loading = true);
    final record = await FirestoreService.cariHariIni(nama);
    setState(() {
      _dicari = true;
      _presensiDitemukan = record;
      _loading = false;
    });
  }

  Future<void> _absenMasuk() async {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) return;
    setState(() => _loading = true);
    final jam = _now.hour * 60 + _now.minute;
    final status = jam <= 8 * 60 ? 'Hadir' : 'Terlambat';
    final record = await FirestoreService.absenMasuk(nama, status);
    setState(() {
      _presensiDitemukan = record;
      _loading = false;
    });
    if (!mounted) return;
    _showDialog(
      '✅ Absen Masuk Berhasil!',
      'Selamat datang, $nama!\nJam masuk: ${_formatJam(_now)}\nStatus: $status',
      Colors.green,
      false,
    );
  }

  Future<void> _absenKeluar() async {
    if (_presensiDitemukan == null) return;
    setState(() => _loading = true);
    final updated = await FirestoreService.absenKeluar(_presensiDitemukan!);
    setState(() {
      _presensiDitemukan = updated;
      _loading = false;
    });
    if (!mounted) return;
    _showDialog(
      '👋 Absen Keluar Berhasil!',
      'Sampai jumpa, ${updated.nama}!\nJam keluar: ${_formatJam(_now)}',
      Colors.orange,
      true,
    );
  }

  void _showDialog(String title, String message, Color color, bool reset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              radius: 36,
              child: Icon(
                  color == Colors.green ? Icons.check_circle : Icons.logout,
                  color: color,
                  size: 40),
            ),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (reset) {
                    setState(() {
                      _namaCtrl.clear();
                      _dicari = false;
                      _presensiDitemukan = null;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _namaCtrl.clear();
      _dicari = false;
      _presensiDitemukan = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sudahMasuk = _presensiDitemukan != null;
    final sudahKeluar = _presensiDitemukan?.jamKeluar != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Presensi Mandiri',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF0E3A8C)]),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${_pad(_now.hour)}:${_pad(_now.minute)}:${_pad(_now.second)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(_formatTanggal(_now),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Lengkap',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _namaCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'Ketik nama Anda...',
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFF1A56DB))),
                          ),
                          onSubmitted: (_) => _cariPresensi(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _loading ? null : _cariPresensi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A56DB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.search),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (!_dicari)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: const Column(
                        children: [
                          Icon(Icons.touch_app, size: 48, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('Ketik nama lalu tekan cari untuk absen',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  else if (sudahKeluar) ...[
                    _InfoBox(
                        icon: Icons.task_alt,
                        color: Colors.grey,
                        title: 'Presensi Hari Ini Selesai',
                        message:
                            'Masuk: ${_formatJam(_presensiDitemukan!.jamMasuk!)}  •  Keluar: ${_formatJam(_presensiDitemukan!.jamKeluar!)}'),
                    const SizedBox(height: 12),
                    TextButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Presensi orang lain')),
                  ] else if (sudahMasuk) ...[
                    _InfoBox(
                        icon: Icons.login,
                        color: Colors.green,
                        title: 'Sudah Absen Masuk',
                        message:
                            '${_presensiDitemukan!.nama} — Jam masuk: ${_formatJam(_presensiDitemukan!.jamMasuk!)}\nStatus: ${_presensiDitemukan!.status}'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _absenKeluar,
                        icon: const Icon(Icons.logout, size: 22),
                        label: const Text('ABSEN KELUAR SEKARANG',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ] else ...[
                    _InfoBox(
                        icon: Icons.person_search,
                        color: const Color(0xFF1A56DB),
                        title: 'Belum absen hari ini',
                        message:
                            'Halo, ${_namaCtrl.text.trim()}! Silakan absen masuk.'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _absenMasuk,
                        icon: const Icon(Icons.login, size: 22),
                        label: const Text('ABSEN MASUK SEKARANG',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Live stream dari Firestore
                  StreamBuilder<List<PresensiRecord>>(
                    stream: FirestoreService.streamHariIni(),
                    builder: (ctx, snap) {
                      final hariIni = snap.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Presensi Hari Ini',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF1A56DB)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text('${hariIni.length} orang',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1A56DB),
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (snap.connectionState == ConnectionState.waiting)
                            const Center(child: CircularProgressIndicator())
                          else if (hariIni.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Belum ada yang absen hari ini',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                              ),
                            )
                          else
                            ...hariIni.map((r) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: _statusColor(r.status)
                                            .withValues(alpha: 0.15),
                                        child: Text(r.nama[0].toUpperCase(),
                                            style: TextStyle(
                                                color: _statusColor(r.status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(r.nama,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13)),
                                            Text(
                                              r.jamKeluar != null
                                                  ? 'Masuk ${_formatJam(r.jamMasuk!)} • Keluar ${_formatJam(r.jamKeluar!)}'
                                                  : 'Masuk ${_formatJam(r.jamMasuk!)}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Chip(
                                        label: Text(r.status,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                        backgroundColor: _statusColor(r.status)
                                            .withValues(alpha: 0.12),
                                        labelStyle: TextStyle(
                                            color: _statusColor(r.status)),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                )),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  const _InfoBox(
      {required this.icon,
      required this.color,
      required this.title,
      required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(message,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Login Page ───────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    if (_usernameCtrl.text == 'admin' && _passwordCtrl.text == 'admin123') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DashboardPage()));
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Username atau password salah'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A56DB), Color(0xFF0E3A8C)]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8))
                        ],
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          size: 44, color: Color(0xFF1A56DB)),
                    ),
                    const SizedBox(height: 20),
                    const Text('PANEL ADMIN',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2)),
                    const Text('Sistem Presensi',
                        style: TextStyle(fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Login Admin',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _usernameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FF),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Wajib diisi'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FF),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Wajib diisi'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A56DB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white))
                                    : const Text('MASUK',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1)),
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
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard Admin ──────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const BerandaTab(),
      const RiwayatTab(),
      const LaporanTab(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1A56DB).withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: Color(0xFF1A56DB)),
              label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: Color(0xFF1A56DB)),
              label: 'Riwayat'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF1A56DB)),
              label: 'Laporan'),
        ],
      ),
    );
  }
}

// ─── Beranda Admin ────────────────────────────────────────────────────────────

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PresensiRecord>>(
      stream: FirestoreService.streamHariIni(),
      builder: (ctx, snap) {
        final today = snap.data ?? [];
        final hadir = today.where((r) => r.status == 'Hadir').length;
        final terlambat = today.where((r) => r.status == 'Terlambat').length;
        final izin = today.where((r) => r.status == 'Izin').length;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 150,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF1A56DB), Color(0xFF0E3A8C)])),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Panel Admin',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    Text('Rekap Presensi',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                  ]),
                              const CircleAvatar(
                                  backgroundColor: Colors.white24,
                                  child: Icon(Icons.admin_panel_settings,
                                      color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_formatTanggal(_now),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text('Total hari ini: ${today.length} orang',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const HomeSelector())),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(children: [
                    _StatCard(
                        label: 'Hadir',
                        nilai: hadir,
                        ikon: Icons.check_circle,
                        warna: Colors.green),
                    const SizedBox(width: 10),
                    _StatCard(
                        label: 'Terlambat',
                        nilai: terlambat,
                        ikon: Icons.access_time,
                        warna: Colors.orange),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _StatCard(
                        label: 'Izin',
                        nilai: izin,
                        ikon: Icons.assignment_outlined,
                        warna: Colors.blue),
                    const SizedBox(width: 10),
                    _StatCard(
                        label: 'Total',
                        nilai: today.length,
                        ikon: Icons.people,
                        warna: const Color(0xFF1A56DB)),
                  ]),
                  const SizedBox(height: 20),
                  const Text('Presensi Hari Ini',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (today.isEmpty)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(children: [
                              Icon(Icons.inbox_outlined,
                                  size: 52, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Belum ada presensi hari ini',
                                  style: TextStyle(color: Colors.grey))
                            ])))
                  else
                    ...today.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RiwayatCard(record: r))),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Riwayat Tab ──────────────────────────────────────────────────────────────

class RiwayatTab extends StatefulWidget {
  const RiwayatTab({super.key});

  @override
  State<RiwayatTab> createState() => _RiwayatTabState();
}

class _RiwayatTabState extends State<RiwayatTab> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Presensi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: const Color(0xFF0E3A8C),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Hadir', 'Terlambat', 'Izin'].map((f) {
                  final sel = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f,
                          style: TextStyle(
                              color: sel
                                  ? const Color(0xFF1A56DB)
                                  : Colors.white70,
                              fontSize: 12)),
                      selected: sel,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: Colors.white,
                      backgroundColor: Colors.white24,
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<PresensiRecord>>(
        stream: FirestoreService.streamSemua(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? [];
          final filtered = _filter == 'Semua'
              ? all
              : all.where((r) => r.status == _filter).toList();

          if (filtered.isEmpty) {
            return const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada data', style: TextStyle(color: Colors.grey))
                ]));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _RiwayatCard(record: filtered[i]),
          );
        },
      ),
    );
  }
}

// ─── Laporan Tab ──────────────────────────────────────────────────────────────

class LaporanTab extends StatelessWidget {
  const LaporanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<PresensiRecord>>(
        stream: FirestoreService.streamSemua(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final riwayat = snap.data ?? [];
          final Map<String, List<PresensiRecord>> byNama = {};
          for (final r in riwayat) {
            byNama.putIfAbsent(r.nama, () => []).add(r);
          }

          if (byNama.isEmpty) {
            return const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada data', style: TextStyle(color: Colors.grey))
                ]));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Rekap Per Orang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...byNama.entries.map((entry) {
                final records = entry.value;
                final hadir = records.where((r) => r.status == 'Hadir').length;
                final terlambat =
                    records.where((r) => r.status == 'Terlambat').length;
                final izin = records.where((r) => r.status == 'Izin').length;
                final total = records.length;
                final persen = total == 0 ? 0.0 : (hadir + terlambat) / total;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                          backgroundColor:
                              const Color(0xFF1A56DB).withValues(alpha: 0.1),
                          radius: 20,
                          child: Text(entry.key[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Color(0xFF1A56DB),
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14))),
                        Text('${(persen * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: persen >= 0.8
                                    ? Colors.green
                                    : persen >= 0.5
                                        ? Colors.orange
                                        : Colors.red)),
                      ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: persen,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(persen >= 0.8
                                  ? Colors.green
                                  : persen >= 0.5
                                      ? Colors.orange
                                      : Colors.red),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _MiniStat('Hadir', hadir, Colors.green),
                            _MiniStat('Terlambat', terlambat, Colors.orange),
                            _MiniStat('Izin', izin, Colors.blue),
                            _MiniStat('Total', total, Colors.grey),
                          ]),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int nilai;
  final IconData ikon;
  final Color warna;
  const _StatCard(
      {required this.label,
      required this.nilai,
      required this.ikon,
      required this.warna});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: warna.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: warna.withValues(alpha: 0.2))),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(ikon, color: warna, size: 20)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$nilai',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: warna)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  final PresensiRecord record;
  const _RiwayatCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(record.status);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              radius: 22,
              child: Text(record.nama[0].toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record.nama,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(_formatTanggal(record.tanggal),
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 4),
              Row(children: [
                if (record.jamMasuk != null)
                  _JamChip(
                      label: 'Masuk',
                      jam: _formatJam(record.jamMasuk!),
                      color: Colors.green),
                if (record.jamMasuk != null && record.jamKeluar != null)
                  const SizedBox(width: 6),
                if (record.jamKeluar != null)
                  _JamChip(
                      label: 'Keluar',
                      jam: _formatJam(record.jamKeluar!),
                      color: Colors.orange),
              ]),
            ]),
          ),
          Chip(
            label: Text(record.status,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            backgroundColor: color.withValues(alpha: 0.12),
            labelStyle: TextStyle(color: color),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ]),
      ),
    );
  }
}

class _JamChip extends StatelessWidget {
  final String label, jam;
  final Color color;
  const _JamChip({required this.label, required this.jam, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text('$label $jam',
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int nilai;
  final Color warna;
  const _MiniStat(this.label, this.nilai, this.warna);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$nilai',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: warna)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatTanggal(DateTime dt) {
  const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  const bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];
  return '${hari[dt.weekday - 1]}, ${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
}

String _formatJam(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

Color _statusColor(String status) {
  switch (status) {
    case 'Hadir':
      return Colors.green;
    case 'Terlambat':
      return Colors.orange;
    case 'Izin':
      return Colors.blue;
    default:
      return Colors.red;
  }
}
