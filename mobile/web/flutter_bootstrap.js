{{flutter_js}}
{{flutter_build_config}}

// Forzar renderer HTML: evita descargar CanvasKit/WASM desde gstatic.com
// (pantalla blanca en red local, sin internet o con firewall).
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      renderer: 'html',
    });
    await appRunner.runApp();
  },
});
