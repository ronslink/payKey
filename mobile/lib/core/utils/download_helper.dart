// Conditional export for cross-platform download
export 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';
