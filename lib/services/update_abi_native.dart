import 'dart:ffi' show Abi;

/// Returns a stable "<os>_<arch>" key for the current platform
/// (e.g. "android_arm64", "windows_x64", "macos_arm64").
String currentAbiKey() {
  final abi = Abi.current();
  if (abi == Abi.androidArm64) return 'android_arm64';
  if (abi == Abi.androidArm) return 'android_arm';
  if (abi == Abi.androidX64) return 'android_x64';
  if (abi == Abi.androidIA32) return 'android_ia32';
  if (abi == Abi.windowsArm64) return 'windows_arm64';
  if (abi == Abi.windowsX64) return 'windows_x64';
  if (abi == Abi.windowsIA32) return 'windows_ia32';
  if (abi == Abi.macosArm64) return 'macos_arm64';
  if (abi == Abi.macosX64) return 'macos_x64';
  if (abi == Abi.linuxArm64) return 'linux_arm64';
  if (abi == Abi.linuxX64) return 'linux_x64';
  if (abi == Abi.linuxIA32) return 'linux_ia32';
  if (abi == Abi.iosArm64) return 'ios_arm64';
  if (abi == Abi.iosArm) return 'ios_arm';
  if (abi == Abi.iosX64) return 'ios_x64';
  return 'unknown';
}
