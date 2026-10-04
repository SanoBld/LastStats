// Picks the right implementation at compile time: dart:ffi is not available
// on web, so the web build gets the stub instead of the native version.
export 'update_abi_stub.dart'
    if (dart.library.ffi) 'update_abi_native.dart';
