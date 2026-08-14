/** Fecha local YYYY-MM-DD (evita desfase UTC con toISOString). */
export function fechaHoyLocal(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

/** "06:00:00" → "6:00 AM" (formato Nicaragua, 12 horas) */
export function formatearHora(hora: string): string {
  return formatearHoraNicaragua(hora);
}

/** Convierte hora 24h (HH:mm o HH:mm:ss) a formato 12h nicaragüense. */
export function formatearHoraNicaragua(hora: string): string {
  const parts = hora.trim().split(':');
  const h24 = parseInt(parts[0] ?? '0', 10);
  const min = (parts[1] ?? '00').slice(0, 2).padStart(2, '0');

  if (Number.isNaN(h24)) return hora;

  const esPm = h24 >= 12;
  let h12 = h24 % 12;
  if (h12 === 0) h12 = 12;

  return `${h12}:${min} ${esPm ? 'PM' : 'AM'}`;
}

/** Parsea "1:30 PM" → "13:30" para enviar al backend */
export function horaNicaraguaA24h(hora12: string): string {
  const match = hora12.trim().match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
  if (!match) return hora12;

  let h = parseInt(match[1], 10);
  const m = match[2];
  const ampm = match[3].toUpperCase();

  if (ampm === 'AM') {
    if (h === 12) h = 0;
  } else if (h !== 12) {
    h += 12;
  }

  return `${String(h).padStart(2, '0')}:${m}`;
}

/** Acepta "6:00 AM" o "06:00" y devuelve "HH:mm" para la API. */
export function horaParaBackend(hora: string): string {
  const t = hora.trim();
  if (/^\d{1,2}:\d{2}\s*(AM|PM)$/i.test(t)) {
    return horaNicaraguaA24h(t);
  }
  const match = t.match(/^(\d{1,2}):(\d{2})(?::(\d{2}))?$/);
  if (match) {
    return `${String(parseInt(match[1], 10)).padStart(2, '0')}:${match[2]}`;
  }
  return t;
}

export type Meridiano = 'AM' | 'PM';

export interface HoraSalidaNicaragua {
  hora: number;
  minuto: string;
  ampm: Meridiano;
}

export const HORA_SALIDA_DEFAULT: HoraSalidaNicaragua = { hora: 6, minuto: '00', ampm: 'AM' };

/** Descompone "06:00" o "18:30:00" en hora 12h + AM/PM. */
export function descomponerHora24(hora24: string): HoraSalidaNicaragua {
  const parts = hora24.trim().split(':');
  const h24 = parseInt(parts[0] ?? '0', 10);
  const min = (parts[1] ?? '00').slice(0, 2).padStart(2, '0');
  if (Number.isNaN(h24) || h24 < 0 || h24 > 23) return HORA_SALIDA_DEFAULT;

  const esPm = h24 >= 12;
  let h12 = h24 % 12;
  if (h12 === 0) h12 = 12;

  return { hora: h12, minuto: min, ampm: esPm ? 'PM' : 'AM' };
}

export function componerHoraNicaragua(v: HoraSalidaNicaragua): string {
  return `${v.hora}:${v.minuto} ${v.ampm}`;
}

export function componerHoraBackend(v: HoraSalidaNicaragua): string {
  return horaNicaraguaA24h(componerHoraNicaragua(v));
}

export function formatearCordobas(monto: number): string {
  return `C$ ${monto.toLocaleString('es-NI', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

export const ETIQUETAS_ESTADO_ASIENTO: Record<string, string> = {
  DISPONIBLE: 'Disponible',
  VENDIDO: 'Vendido',
  CANCELADO: 'Cancelado',
  RESERVADO_EXCEPCIONAL: 'Reserva excepcional',
};

export type PosicionAsiento =
  | 'VENTANA'
  | 'PASILLO'
  | 'TRASERA_1'
  | 'TRASERA_2'
  | 'TRASERA_3'
  | 'TRASERA_4'
  | 'TRASERA_5';

export const ETIQUETAS_POSICION_ASIENTO: Record<string, string> = {
  VENTANA: 'Ventana',
  PASILLO: 'Pasillo',
  TRASERA_1: 'Trasera',
  TRASERA_2: 'Trasera',
  TRASERA_3: 'Trasera',
  TRASERA_4: 'Trasera',
  TRASERA_5: 'Trasera',
};

export function etiquetaPosicionAsiento(posicion: string): string {
  if (posicion.startsWith('TRASERA')) return 'Fila trasera';
  return ETIQUETAS_POSICION_ASIENTO[posicion] ?? posicion;
}

export function esAsientoVentana(posicion: string): boolean {
  return posicion === 'VENTANA';
}

export function esAsientoTrasera(posicion: string): boolean {
  return posicion.startsWith('TRASERA');
}

export const ETIQUETAS_ESTADO_VIAJE: Record<string, string> = {
  PROGRAMADO: 'Programado',
  EN_CURSO: 'En curso',
  COMPLETADO: 'Completado',
  CANCELADO: 'Cancelado',
};
