import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri_date_time/hijri_date_time.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wear/wear.dart';
import 'package:intl/intl.dart';

void main() => runApp(const NamazWatchApp());

class NamazWatchApp extends StatelessWidget {
  const NamazWatchApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Namaz Watch',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const WatchFace(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WatchFace extends StatefulWidget {
  const WatchFace({super.key});
  @override
  State<WatchFace> createState() => _WatchFaceState();
}

class _WatchFaceState extends State<WatchFace> {
  final player = AudioPlayer();
  final notif = FlutterLocalNotificationsPlugin();
  PrayerTimes? times;
  HijriDateTime? hijri;
  Position? pos;
  double? qibla;

  @override
  void initState() {
    super.initState();
    _initNotif();
    _getLocation();
    Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  Future<void> _initNotif() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notif.initialize(const InitializationSettings(android: android));
  }

  Future<void> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    pos = await Geolocator.getCurrentPosition();
    _calcTimes();
    _calcHijri();
    _calcQibla();
  }

  void _calcTimes() {
    if (pos == null) return;
    final coords = Coordinates(pos!.latitude, pos!.longitude);
    final params = CalculationMethod.ummAlQura();
    times = PrayerTimes.today(coords, params);
    setState(() {});
  }

  void _calcHijri() {
    hijri = HijriDateTime.now();
    setState(() {});
  }

  void _calcQibla() {
    if (pos == null) return;
    qibla = Qibla(Coordinates(pos!.latitude, pos!.longitude)).direction;
    setState(() {});
  }

  Future<void> _playAzan() async {
    await player.play(AssetSource('audio/azan.mp3'));
    await notif.show(1, 'آذان', 'نماز کی تیاری کریں', const NotificationDetails(
      android: AndroidNotificationDetails('azan', 'Azan'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return WearShapeBuilder(
      builder: (context, shape) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF388E3C)]),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('HH:mm:ss').format(DateTime.now()),
                      style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('شمسی: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: const TextStyle(color: Colors.white70)),
                  Text('ہجری: ${hijri?.toString().substring(0, 10) ?? '--'}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  if (times != null) ...[
                    _timeRow('فجر', times!.fajr),
                    _timeRow('ظہر', times!.dhuhr),
                    _timeRow('عصر', times!.asr),
                    _timeRow('مغرب', times!.maghrib),
                    _timeRow('عشاء', times!.isha),
                  ],
                  if (qibla != null)
                    Transform.rotate(
                      angle: qibla! * 3.14159 / 180,
                      child: const Icon(Icons.explore, size: 40, color: Colors.yellow),
                    ),
                  ElevatedButton(onPressed: _playAzan, child: const Text('اذان')),
                  const SizedBox(height: 16),
                  const Text('میڈ بائے: حافظ مفتی محمد شعیب خاں آلائی',
                      style: TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeRow(String name, DateTime time) => Text('$name: ${DateFormat('HH:mm').format(time)}',
      style: const TextStyle(color: Colors.white));
}
