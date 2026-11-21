// lib/services/net_status.dart
// Holds the last network error. Pages keep showing cached data;
// the error icon reads this to show the details.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NetStatus {
  NetStatus._();
  static final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  // Number of background refreshes running (spinner shows while > 0).
  static final ValueNotifier<int> loading = ValueNotifier<int>(0);
  static void begin() => loading.value++;
  static void end() { if (loading.value > 0) loading.value--; }
}

/// Small error icon, hidden when there is no error. Tap = details.
class NetErrorButton extends StatelessWidget {
  const NetErrorButton({super.key});

  static void showDetails(BuildContext ctx, String err) => showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.error_outline_rounded),
          content: SelectableText(err),
          actions: [
            TextButton(
              onPressed: () { NetStatus.error.value = null; Navigator.pop(ctx); },
              child: const Text('OK'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
        valueListenable: NetStatus.error,
        builder: (ctx, err, _) => ValueListenableBuilder<int>(
          valueListenable: NetStatus.loading,
          builder: (ctx, busy, _) {
            if (err != null) {
              return IconButton.filledTonal(
                icon: Icon(Icons.error_outline_rounded,
                    color: Theme.of(ctx).colorScheme.error),
                onPressed: () => showDetails(ctx, err),
              );
            }
            if (busy > 0) {
              return const SizedBox(
                width: 48, height: 48,
                child: Center(
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
}
