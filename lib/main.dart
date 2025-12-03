import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String? _captainName; // Login required
  int _pageIndex = 0;
  late Trip _trip;
  List<Cistern> _cisterns = [];

  List<String> get _rswTanks => RSW_TANKS;

  // Maritime Theme Colors
  final Color _primaryBlue = const Color(0xFF0A2342); // Deep Ocean
  final Color _secondaryBlue = const Color(0xFF0F3460); // Night Sea
  final Color _accentTeal = const Color(0xFF2CA58D); // Sea Foam
  final Color _surfaceWhite = const Color(0xFFF0F4F8); // Mist
  final Color _errorRed = const Color(0xFFE94560); // Warning

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

  void _handleLogout() {
    setState(() {
      _captainName = null;
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
          seedColor: _primaryBlue,
          primary: _primaryBlue,
          secondary: _accentTeal,
          surface: _surfaceWhite,
          error: _errorRed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: _surfaceWhite,
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: _accentTeal.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: _primaryBlue,
          selectedIconTheme: IconThemeData(color: _accentTeal),
          unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.6)),
          selectedLabelTextStyle: GoogleFonts.lato(color: _accentTeal, fontWeight: FontWeight.bold),
          unselectedLabelTextStyle: GoogleFonts.lato(color: Colors.white.withOpacity(0.6)),
        ),
      ),
      home: _captainName == null
          ? LoginPage(onLogin: _handleLogin)
          : _Shell(
              captainName: _captainName!,
              pageIndex: _pageIndex,
              onTabChange: (i) => setState(() => _pageIndex = i),
              onLogout: _handleLogout,
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
  final VoidCallback onLogout;
  final Widget speciesPage;
  final Widget cisternsPage;
  final Widget summaryPage;

  const _Shell({
    required this.captainName,
    required this.pageIndex,
    required this.onTabChange,
    required this.onLogout,
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
            selectedIcon: Icon(Icons.science),
            label: 'Species Sampling',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Cistern Logistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Trip Summary',
          ),
        ];

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: pageIndex,
                  onDestinationSelected: onTabChange,
                  extended: true,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const Icon(Icons.sailing, color: Colors.white, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'RSW FLEET',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.science_outlined),
                      selectedIcon: Icon(Icons.science),
                      label: Text('Species Sampling'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_shipping_outlined),
                      selectedIcon: Icon(Icons.local_shipping),
                      label: Text('Cistern Logistics'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Trip Summary'),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      AppBar(
                        title: Text('Captain $captainName'),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0A2342),
                        elevation: 1,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout),
                            onPressed: onLogout,
                            tooltip: 'Logout',
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                      Expanded(child: pages[pageIndex]),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  'RSW FLEET MANAGER',
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1),
                ),
                Text(
                  'Captain $captainName',
                  style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: onLogout,
              ),
            ],
          ),
          body: pages[pageIndex],
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
