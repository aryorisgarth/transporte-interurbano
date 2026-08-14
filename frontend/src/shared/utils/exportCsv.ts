/** Exporta filas a CSV (Excel lo abre directamente). */
export function exportarCsv(
  filename: string,
  headers: string[],
  rows: (string | number | null | undefined)[][]
) {
  const escape = (v: string | number | null | undefined) => {
    const s = v == null ? '' : String(v);
    if (/[",\n]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
    return s;
  };

  const lines = [
    headers.map(escape).join(','),
    ...rows.map((row) => row.map(escape).join(',')),
  ];

  const blob = new Blob(['\uFEFF' + lines.join('\n')], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

/** Abre diálogo de impresión (PDF vía "Guardar como PDF" del navegador). */
export function imprimirElemento(elementId: string, titulo: string) {
  const el = document.getElementById(elementId);
  if (!el) return;

  const ventana = window.open('', '_blank', 'width=900,height=700');
  if (!ventana) return;

  ventana.document.write(`
    <!DOCTYPE html>
    <html><head>
      <title>${titulo}</title>
      <style>
        body { font-family: Arial, sans-serif; padding: 24px; font-size: 12px; }
        h1 { font-size: 18px; margin-bottom: 8px; }
        p { color: #555; margin-bottom: 16px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ccc; padding: 6px 8px; text-align: left; }
        th { background: #f0f0f0; }
      </style>
    </head><body>
      <h1>${titulo}</h1>
      ${el.innerHTML}
    </body></html>
  `);
  ventana.document.close();
  ventana.focus();
  ventana.print();
}
