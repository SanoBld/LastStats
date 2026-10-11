import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';

/// Applies the user's text size (on top of the system one) and font family
/// to the whole app.
class AppTextScale extends StatelessWidget {
  final Widget child;
  const AppTextScale({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: textScaleNotifier,
      builder: (_, scale, _) => ValueListenableBuilder<String>(
        valueListenable: appFontNotifier,
        builder: (_, font, _) {
          final mq = MediaQuery.of(context);
          var theme = Theme.of(context);
          if (font.isNotEmpty) {
            theme = theme.copyWith(
              textTheme: theme.textTheme.apply(fontFamily: font),
              primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: font),
            );
          }
          return MediaQuery(
            data: mq.copyWith(
                textScaler: TextScaler.linear(mq.textScaler.scale(1) * scale)),
            // Status bar icons follow the app theme (not the phone's): dark
            // icons on a light app, light icons on a dark app.
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    theme.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
                statusBarBrightness: theme.brightness,
              ),
              child: Theme(data: theme, child: child),
            ),
          );
        },
      ),
    );
  }
}
