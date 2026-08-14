import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'consulta_mobile_app.dart';
import 'core/auth/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Móvil nativo: solo consulta pública (diseño pasajero).
  // Web: app completa (consulta + cajero + admin), equivalente a React.
  if (kIsWeb) {
    final auth = AuthProvider();
    await auth.loadSession();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: TransporteApp(auth: auth),
      ),
    );
  } else {
    runApp(const ConsultaMobileApp());
  }
}
