import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'constants.dart';
import 'firebase_options.dart';
import 'models/cistern.dart';
import 'models/trip.dart';
import 'pages/cisterns_page.dart';
import 'pages/login_page.dart';
import 'pages/species_page.dart';
import 'pages/summary_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Disable Firestore cache for web
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  debugPrint('Firestore persistence disabled');

  runApp(const RswFleetApp());
}

class RswFleetApp extends StatefulWidget {
  const RswFleetApp({super.key});

  @override
  State<RswFleetApp> createState() => _RswFleetAppState();
}

class _RswFleetAppState extends State<RswFleetApp> {
  String? _captainName;
  int _pageIndex = 0;
  late Trip _trip;
  List<Cistern> _cisterns = [];

  List<String> get _rswTanks => RSW_TANKS;

  @override
  void initState() {
    super.initState();
    _trip = Trip(
      id: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
      tripCode: 'TRIP-${DateFormat('yyMMdd-HHmm').format(DateTime.now())}',
      tripDate: DateTime.now().toString().split(' ').first,
      vessel: 'M/V Ocean Venture',
    );
  }

  void _handleLogin(String captain) {
    setState(() {
      _captainName = captain;
    });
  }

  void _handleDateChange(String date) {
    setState(() {
      _trip.tripDate = date;
    });
  }

  void _handleCisternsChange(List<Cistern> updated) {
    setState(() {
      _cisterns = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RSW Fleet Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5E9), // ocean blue
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5FBFF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF0F172A),
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Color(0x1A0EA5E9),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
      ),
      home: _captainName == null
          ? LoginPage(onLogin: _handleLogin)
          : _Shell(
              captainName: _captainName!,
              pageIndex: _pageIndex,
              onTabChange: (i) => setState(() => _pageIndex = i),
              speciesPage: SpeciesPage(
                tripData: _trip,
                onDateChange: _handleDateChange,
                rswTanks: _rswTanks,
              ),
              cisternsPage: CisternsPage(
                rswTanks: _rswTanks,
                buyers: BUYERS,
                cisternsData: _cisterns,
                onCisternsChange: _handleCisternsChange,
              ),
              summaryPage: SummaryPage(cisternsData: _cisterns),
            ),
    );
  }
}

class _Shell extends StatelessWidget {
  final String captainName;
  final int pageIndex;
  final ValueChanged<int> onTabChange;
  final Widget speciesPage;
  final Widget cisternsPage;
  final Widget summaryPage;

  const _Shell({
    required this.captainName,
    required this.pageIndex,
    required this.onTabChange,
    required this.speciesPage,
    required this.cisternsPage,
    required this.summaryPage,
  });

  @override
  Widget build(BuildContext context) {
    final pages = [
      speciesPage,
      cisternsPage,
      summaryPage,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;
        final destinations = const [
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            label: 'Species',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            label: 'Cisterns',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Summary',
          ),
        ];

        if (isWide) {
          return Scaffold(
            appBar: AppBar(
              title: Text('RSW Fleet - Captain $captainName'),
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: pageIndex,
                  onDestinationSelected: onTabChange,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.science_outlined),
                      label: Text('Species'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_shipping_outlined),
                      label: Text('Cisterns'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      label: Text('Summary'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: SafeArea(child: pages[pageIndex])),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('RSW Fleet - Captain $captainName'),
          ),
          body: SafeArea(child: pages[pageIndex]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: pageIndex,
            onDestinationSelected: onTabChange,
            destinations: destinations,
          ),
        );
      },
    );
  }
}
