// lib/screens/qr_scanner_page.dart
// Scans a LastStats/Last.fm profile QR code with the camera, then opens
// the normal profile sheet (already has stats + the add/remove friend
// button) — no need for a separate custom preview UI.
part of 'home_screen.dart';

void showQrScannerPage(BuildContext context, LastFmService service) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => _QrScannerPage(service: service),
  ));
}

class _QrScannerPage extends StatefulWidget {
  final LastFmService service;
  const _QrScannerPage({required this.service});

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  Set<String> _favProfiles = {};
  bool _handled = false; // stop re-triggering while the profile sheet is open
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _favProfiles = Set<String>.from(p.getStringList('ls_fav_profiles') ?? []));
  }

  Future<void> _toggleFav(String username, bool nowFav) async {
    final updated = Set<String>.from(_favProfiles);
    if (nowFav) { updated.add(username); } else { updated.remove(username); }
    final p = await SharedPreferences.getInstance();
    await p.setStringList('ls_fav_profiles', updated.toList());
    if (mounted) setState(() => _favProfiles = updated);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      final username = QrLinkService.usernameFromScan(raw);
      if (username != null) {
        _handled = true;
        HapticFeedback.mediumImpact();
        showProfileSheet(
          context, username, widget.service,
          isFav: _favProfiles.contains(username),
          onToggleFav: () => _toggleFav(username, !_favProfiles.contains(username)),
        );
        // Allow scanning again once the profile sheet is dismissed.
        Future.delayed(const Duration(milliseconds: 800), () { _handled = false; });
        return;
      }
    }
    if (!mounted || _error != null) return;
    setState(() => _error = _ct('QR non reconnu — pas un profil LastStats/Last.fm',
        'QR not recognized — not a LastStats/Last.fm profile'));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        // Simple viewfinder frame, purely visual.
        Center(
          child: Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white70, width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8, left: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
        Positioned(
          left: 0, right: 0, bottom: 48,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_ct('Scanne un QR code de profil', "Scan a profile's QR code"),
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
