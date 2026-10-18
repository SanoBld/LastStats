// Builds the Flutter web app.
// Usage: dart run tool/ci/build_web.dart /LastStats/app/
import 'dart:io';

Future<void> run(List<String> args) async {
  final p = await Process.start('flutter', args,
      mode: ProcessStartMode.inheritStdio, runInShell: Platform.isWindows);
  final code = await p.exitCode;
  if (code != 0) exit(code);
}

Future<void> main(List<String> args) async {
  // base-href must match the repo name + /app/ subfolder
  final baseHref = args.isNotEmpty ? args.first : '/';
  await run(['pub', 'get']);
  await run(['build', 'web', '--release', '--base-href', baseHref]);
}
