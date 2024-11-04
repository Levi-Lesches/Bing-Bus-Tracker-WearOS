import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_arc_text/flutter_arc_text.dart";

import "package:spot/spot.dart";
import "package:spot/bc.dart";
import "package:wear_os_plugin/wear_os_clipper.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      home: const HomePage(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(surface: Colors.black),
        visualDensity: VisualDensity.compact,
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<HomePage> {
  static const refreshInterval = Duration(seconds: 30);
  final spot = SpotApi();
  final bc = BcApi();

  String time = "(Time)";
  String status = "Loading...";
  String spotMessage = "...";
  String bcMessage = "...";
  bool didInit = false;
  Timer? timer;

  bool invalid = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget buildEta({required String eta, required String name}) => Column(
    children: [
      Text(name, style: context.textTheme.bodySmall),
      Text(eta, style: invalid ? context.textTheme.headlineSmall : context.textTheme.headlineMedium),
    ],
  );

  Future<void> init() async {
    try {
      setState(() => status = "Loading SPOT...");
      await spot.init();
      setState(() => status = "Loading BC...");
      await bc.init();
    } catch (error) {
      setState(() => status = "Error initializing");
      rethrow;
    }
    timer = Timer.periodic(refreshInterval, refresh);
    refresh().ignore();
    didInit = true;
    setState(() { });
  }

  Future<void> refresh([_]) async {
    invalid = false;
    setState(() => time = context.time);
    try {
      setState(() => spotMessage = "...");
      final spotEta = await spot.getEta();
      invalid = invalid || spotEta == null;
      setState(() => spotMessage = spotEta == null ? "No bus" : "${spotEta.inMinutes} m");
    } catch (error) {
      invalid = true;
      spotMessage = "Error";
    }
    try {
      setState(() => bcMessage = "...");
      final bcEta = await bc.getEta();
      invalid = invalid || bcEta == null;
      setState(() => bcMessage = bcEta == null ? "No bus" : "${bcEta.inMinutes} m");
    } catch (error) {
      invalid = true;
      bcMessage = "Error";
    }
    setState(() { });
  }

  @override
  Widget build(BuildContext context) => WearOsClipper(child: Scaffold(
    body: !didInit
      ? Center(child: Text(status))
      : Stack(children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ArcText(
              text: time,
              textStyle: context.textTheme.bodyMedium,
              startAngleAlignment: StartAngleAlignment.center,
              radius: 100,
              placement: Placement.inside,
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("ETA to UClub", style: context.textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildEta(eta: spotMessage, name: "OCCT"),
                  const SizedBox(width: 16),
                  buildEta(eta: bcMessage, name: "BC"),
              ],),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    floatingActionButton: FilledButton.icon(
      onPressed: didInit ? refresh : init,
      icon: const Icon(Icons.refresh),
      label: const Text("Refresh"),
    ),
  ),);
}

extension on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  String get time => MaterialLocalizations.of(this).formatTimeOfDay(TimeOfDay.now());
}
