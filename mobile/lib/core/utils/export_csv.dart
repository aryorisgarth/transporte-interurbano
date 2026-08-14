/// Descarga CSV en web; en otras plataformas no-op.
library;

export 'export_csv_stub.dart'
    if (dart.library.html) 'export_csv_web.dart';
