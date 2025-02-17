import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(CountdownApp());
}

class CountdownApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TermsAndConditionsPage(),
    );
  }
}

class TermsAndConditionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Accord d\'utilisation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              const Text(
                'En accédant à cette application, vous acceptez d’être lié par les termes et conditions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  // Vérifie si l'heure de fin est déjà stockée
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  DateTime? storedEndTime =
                      DateTime.tryParse(prefs.getString('endTime') ?? '');

                  if (storedEndTime != null) {
                    // Si l'heure de fin est stockée, on l'utilise
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CountdownScreen(storedEndTime)),
                    );
                  } else {
                    // Sinon, on génère une nouvelle heure de fin et on la stocke
                    int randomHours = Random().nextInt(100);
                    DateTime newEndTime =
                        DateTime.now().add(Duration(hours: randomHours));
                    await prefs.setString(
                        'endTime', newEndTime.toIso8601String());
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CountdownScreen(newEndTime)),
                    );
                  }
                },
                child: const Text('J\'accepte'),
                style: ElevatedButton.styleFrom(primary: Colors.red),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  launchURL('http://sidibe-arouna.vercel.app/');
                },
                child: Text(
                  'Visitez mon Portfolio',
                  style: TextStyle(
                      color: Color.fromARGB(255, 49, 48, 48), fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class CountdownScreen extends StatefulWidget {
  final DateTime endTime;

  CountdownScreen(this.endTime);

  @override
  _CountdownScreenState createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late DateTime endTime;
  late Duration remainingTime;
  late AudioPlayer _audioPlayer;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    endTime = widget.endTime;
    remainingTime = endTime.difference(DateTime.now());
    _audioPlayer = AudioPlayer();
    _timer = Timer.periodic(Duration(minutes: 60), (timer) {
      _playBip();
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime = endTime.difference(DateTime.now());
        if (remainingTime.isNegative) {
          _timer.cancel();
          _showDeathAlert();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playBip() async {
    await _audioPlayer.play(AssetSource('assets/countdown.mp3'));
  }

  void _showDeathAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Le temps est écoulé...',
            style: TextStyle(
                color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Votre fin approche. ⚠️',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    int years = duration.inDays ~/ 365;
    int months = (duration.inDays % 365) ~/ 30;
    int days = duration.inDays % 365 % 30;

    String twoDigitsYears = twoDigits(years);
    String twoDigitsMonths = twoDigits(months);
    String twoDigitsDays = twoDigits(days);
    String twoDigitsHours = twoDigits(duration.inHours.remainder(24));
    String twoDigitsMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitsSeconds = twoDigits(duration.inSeconds.remainder(60));

    return "$twoDigitsYears:$twoDigitsMonths:$twoDigitsDays:$twoDigitsHours:$twoDigitsMinutes:$twoDigitsSeconds";
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = formatDuration(remainingTime);
    List<String> timeParts = formattedTime.split(':');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeColumn(timeParts[0], 'Années'),
                  SizedBox(width: 10),
                  _buildTimeColumn(timeParts[1], 'Mois'),
                  SizedBox(width: 10),
                  _buildTimeColumn(timeParts[2], 'Jours'),
                  SizedBox(width: 10),
                  _buildTimeColumn(timeParts[3], 'Heures'),
                  SizedBox(width: 10),
                  _buildTimeColumn(timeParts[4], 'Minutes'),
                  SizedBox(width: 10),
                  _buildTimeColumn(timeParts[5], 'Secondes'),
                ],
              ),
              SizedBox(height: 2),
              TextButton(
                onPressed: () {
                  launchURL('http://sidibe-arouna.vercel.app/');
                },
                child: Text(
                  'Visitez mon Portfolio',
                  style: TextStyle(
                      color: Color.fromARGB(255, 49, 48, 48), fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String timePart, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timePart,
          style: TextStyle(
            color: timePart == "00" ? Colors.red : Colors.white,
            fontSize: 70,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
