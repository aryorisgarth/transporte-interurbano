import { jsPDF } from 'jspdf';
import type { VentaResponse } from '@/shared/api';
import { formatearCordobas } from './formato';

interface ViajeInro {
  origen: string;
  destino: string;
  fecha: string;
  hora: string;
  empresa: string;
}

export function descargarComprobantePdf(
  venta: VentaResponse,
  viajeInfo?: ViajeInro
): void {
  const doc = new jsPDF({ unit: 'mm', format: 'a5' });
  const empresa = viajeInfo?.empresa ?? 'Transporte Interurbano';
  let y = 18;

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(14);
  doc.text(empresa, 74, y, { align: 'center' });
  y += 6;

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(10);
  doc.text('Bluefields – Managua', 74, y, { align: 'center' });
  y += 8;

  doc.setDrawColor(180);
  doc.line(14, y, 134, y);
  y += 8;

  doc.setFontSize(10);
  const lineas: string[] = [
    `Código: ${venta.codigo}`,
  ];

  if (viajeInfo) {
    lineas.push(
      `Viaje: ${viajeInfo.origen} → ${viajeInfo.destino}`,
      `Fecha: ${viajeInfo.fecha} ${viajeInfo.hora}`
    );
  }

  lineas.push(
    `Comprador: ${venta.compradorNombre}`,
    `Cédula: ${venta.compradorCedula}`,
    `Asientos: ${venta.numerosAsiento.join(', ')}`,
    '',
    `Boletos: ${formatearCordobas(Number(venta.subtotalBoletos))}`
  );

  if (Number(venta.subtotalEquipaje) > 0) {
    lineas.push(`Equipaje extra: ${formatearCordobas(Number(venta.subtotalEquipaje))}`);
  }

  lineas.push(`Total: ${formatearCordobas(Number(venta.total))}`);

  for (const linea of lineas) {
    if (linea === '') {
      y += 3;
      continue;
    }
    doc.text(linea, 14, y);
    y += 6;
  }

  y += 4;
  doc.setFontSize(8);
  doc.setTextColor(100);
  doc.text('1 equipaje incluido por boleto. Presente este comprobante en terminal.', 14, y, {
    maxWidth: 120,
  });

  doc.save(`comprobante-${venta.codigo}.pdr`);
}
