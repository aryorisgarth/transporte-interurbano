import type {
  AsientoBus,
  AsientoViaje,
  Bus,
  DetalleCooperativa,
  DetalleViaje,
  Empresa,
  IngresosReporte,
  ManifiestoPasajero,
  OcupacionViaje,
  ParadaRuta,
  ResumenEmpresa,
  UsuarioPerfil,
  VentaResponse,
  ViajeDisponible,
  ViajeOperador,
} from '@/shared/api/types';
import { ROLES } from '@/shared/utils/jwt';

export function fechaHoyIso(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function buildAsientosBus(busId: number, vendidos: number[] = []): AsientoBus[] {
  const asientos: AsientoBus[] = [];
  let numero = 1;
  for (let fila = 1; fila <= 12; fila++) {
    for (const pos of ['VENTANA', 'PASILLO'] as const) {
      if (numero > 45) break;
      asientos.push({ id: busId * 100 + numero, numero, fila, posicion: pos });
      numero++;
    }
  }
  for (let i = 1; i <= 5; i++) {
    asientos.push({
      id: busId * 100 + numero,
      numero,
      fila: 13,
      posicion: `TRASERA_${i}` as AsientoBus['posicion'],
    });
    numero++;
  }
  return asientos;
}

function buildAsientosViaje(viajeId: number, vendidos: number[] = []): AsientoViaje[] {
  return buildAsientosBus(viajeId).map((a) => ({
    viajeAsientoId: viajeId * 1000 + a.numero,
    numero: a.numero,
    fila: a.fila,
    posicion: a.posicion,
    estado: vendidos.includes(a.numero) ? 'VENDIDO' : ('DISPONIBLE' as const),
  }));
}

export const mockEmpresas: Empresa[] = [
  {
    id: 1,
    nombre: 'Wendelyn Transporte',
    telefono: '2572-3456',
    correo: 'info@wendelyn.com',
    tarifaEquipajeExtra: 150,
    logoUrl: null,
    activo: true,
  },
  {
    id: 2,
    nombre: 'Martínez Líneas',
    telefono: '2572-7890',
    correo: 'info@martinez.com',
    tarifaEquipajeExtra: 120,
    logoUrl: null,
    activo: true,
  },
];

export const mockBuses: Bus[] = [
  {
    id: 1,
    empresaId: 1,
    numeroInterno: 'W-01',
    placa: 'NI-1001',
    capacidad: 50,
    filas: 13,
    activo: true,
    fotoUrl: '/images/bus-yutong-interurbano.png',
    sede: 'Bluefields',
    asientos: buildAsientosBus(1),
  },
  {
    id: 2,
    empresaId: 1,
    numeroInterno: 'W-02',
    placa: 'NI-1002',
    capacidad: 50,
    filas: 13,
    activo: true,
    fotoUrl: '/images/bus-yutong-interurbano.png',
    sede: 'Managua',
    asientos: buildAsientosBus(2),
  },
  {
    id: 3,
    empresaId: 2,
    numeroInterno: 'M-01',
    placa: 'NI-2001',
    capacidad: 50,
    filas: 13,
    activo: true,
    fotoUrl: '/images/bus-yutong-interurbano.png',
    sede: 'Bluefields',
    asientos: buildAsientosBus(3),
  },
];

const vendidosViaje1 = [1, 2, 3, 5, 8, 12, 15, 20, 22, 30];

export function mockViajesOperador(fecha: string): ViajeOperador[] {
  return [
    {
      id: 101,
      empresaId: 1,
      empresaNombre: 'Wendelyn Transporte',
      busId: 1,
      busNumeroInterno: 'W-01',
      origen: 'Bluefields',
      destino: 'Managua',
      fecha,
      horaSalida: '06:00:00',
      tarifa: 350,
      tarifaEquipajeExtra: 150,
      estado: 'PROGRAMADO',
      asientosDisponibles: 50 - vendidosViaje1.length,
    },
    {
      id: 102,
      empresaId: 1,
      empresaNombre: 'Wendelyn Transporte',
      busId: 2,
      busNumeroInterno: 'W-02',
      origen: 'Managua',
      destino: 'Bluefields',
      fecha,
      horaSalida: '14:30:00',
      tarifa: 350,
      tarifaEquipajeExtra: 150,
      estado: 'PROGRAMADO',
      asientosDisponibles: 42,
    },
    {
      id: 201,
      empresaId: 2,
      empresaNombre: 'Martínez Líneas',
      busId: 3,
      busNumeroInterno: 'M-01',
      origen: 'Bluefields',
      destino: 'Managua',
      fecha,
      horaSalida: '07:30:00',
      tarifa: 320,
      tarifaEquipajeExtra: 120,
      estado: 'PROGRAMADO',
      asientosDisponibles: 38,
    },
  ];
}

export function mockViajesDisponibles(fecha: string): ViajeDisponible[] {
  return mockViajesOperador(fecha)
    .filter((v) => v.origen === 'Bluefields' && v.destino === 'Managua')
    .map((v) => ({
      viajeId: v.id,
      empresaNombre: v.empresaNombre,
      empresaLogoUrl: null,
      horaSalida: v.horaSalida,
      asientosDisponibles: v.asientosDisponibles,
      capacidadTotal: 50,
      tarifa: v.tarifa,
    }));
}

export const mockParadas: ParadaRuta[] = [
  {
    id: 1,
    nombre: 'Terminal Bluefields',
    orden: 1,
    minutosDesdeSalida: 0,
    horaEstimada: '06:00:00',
    latitud: 12.0131,
    longitud: -83.7634,
  },
  {
    id: 2,
    nombre: 'El Rama',
    orden: 2,
    minutosDesdeSalida: 90,
    horaEstimada: '07:30:00',
    latitud: 12.1597,
    longitud: -84.2192,
  },
  {
    id: 3,
    nombre: 'Juigalpa',
    orden: 3,
    minutosDesdeSalida: 300,
    horaEstimada: '11:00:00',
    latitud: 12.106,
    longitud: -85.364,
  },
  {
    id: 4,
    nombre: 'Terminal Managua',
    orden: 4,
    minutosDesdeSalida: 480,
    horaEstimada: '14:00:00',
    latitud: 12.1364,
    longitud: -86.2514,
  },
];

export function mockDetalleViajePublico(viajeId: number): DetalleViaje | null {
  const viaje = mockViajesOperador(fechaHoyIso()).find((v) => v.id === viajeId);
  if (!viaje) return null;

  const vendidos = viajeId === 101 ? vendidosViaje1 : viajeId === 102 ? [4, 6, 7] : [10, 11];
  const bus = mockBuses.find((b) => b.id === viaje.busId);

  return {
    viajeId: viaje.id,
    empresaNombre: viaje.empresaNombre,
    empresaLogoUrl: null,
    busNumeroInterno: viaje.busNumeroInterno,
    busFotoUrl: bus?.fotoUrl ?? null,
    origen: viaje.origen,
    destino: viaje.destino,
    fecha: viaje.fecha,
    horaSalida: viaje.horaSalida,
    tarifa: viaje.tarifa,
    tarifaEquipajeExtra: viaje.tarifaEquipajeExtra ?? 150,
    asientosDisponibles: viaje.asientosDisponibles,
    asientos: buildAsientosViaje(viajeId, vendidos),
    paradas: mockParadas,
  };
}

export function mockDetalleViajeOperador(viajeId: number): DetalleViaje | null {
  return mockDetalleViajePublico(viajeId);
}

export const mockPerfil: UsuarioPerfil = {
  id: 1,
  empresaId: 1,
  empresaNombre: 'Wendelyn Transporte',
  nombreUsuario: 'demo',
  emailLogin: 'demo@transporte.com',
  nombreCompleto: 'Usuario Demo',
  sede: 'Bluefields',
  activo: true,
  roles: [ROLES.ADMIN_GENERAL, ROLES.ADMIN_EMPRESA, ROLES.CAJERO],
};

export const mockOperadores: UsuarioPerfil[] = [
  mockPerfil,
  {
    id: 2,
    empresaId: 1,
    empresaNombre: 'Wendelyn Transporte',
    nombreUsuario: 'cajero.wendelyn',
    emailLogin: 'cajero@wendelyn.com',
    nombreCompleto: 'Cajero Wendelyn',
    sede: 'Bluefields',
    activo: true,
    roles: [ROLES.CAJERO],
  },
  {
    id: 3,
    empresaId: 1,
    empresaNombre: 'Wendelyn Transporte',
    nombreUsuario: 'admin.wendelyn',
    emailLogin: 'admin@wendelyn.com',
    nombreCompleto: 'Admin Wendelyn',
    sede: 'Bluefields',
    activo: true,
    roles: [ROLES.ADMIN_EMPRESA],
  },
];

export const mockResumenPlataforma: ResumenEmpresa[] = [
  {
    id: 1,
    nombre: 'Wendelyn Transporte',
    activo: true,
    busesActivos: 2,
    operadoresActivos: 3,
    viajesHoy: 2,
    boletosVendidosHoy: 18,
  },
  {
    id: 2,
    nombre: 'Martínez Líneas',
    activo: true,
    busesActivos: 1,
    operadoresActivos: 2,
    viajesHoy: 1,
    boletosVendidosHoy: 12,
  },
];

export function mockDetalleCooperativa(empresaId: number): DetalleCooperativa {
  const empresa = mockEmpresas.find((e) => e.id === empresaId) ?? mockEmpresas[0];
  const buses = mockBuses.filter((b) => b.empresaId === empresaId);

  return {
    empresa,
    metricas: {
      busesActivos: buses.filter((b) => b.activo).length,
      busesInactivos: buses.filter((b) => !b.activo).length,
      adminsActivos: 1,
      adminsInactivos: 0,
      cajerosActivos: 1,
      cajerosInactivos: 0,
      viajesHoy: mockViajesOperador(fechaHoyIso()).filter((v) => v.empresaId === empresaId).length,
      boletosVendidosHoy: empresaId === 1 ? 18 : 12,
    },
    operadores: mockOperadores
      .filter((o) => o.empresaId === empresaId)
      .map((o) => ({
        id: o.id,
        nombreUsuario: o.nombreUsuario,
        emailLogin: o.emailLogin ?? '',
        nombreCompleto: o.nombreCompleto,
        sede: o.sede,
        activo: o.activo ?? true,
        roles: o.roles,
      })),
    buses: buses.map((b) => ({
      id: b.id,
      numeroInterno: b.numeroInterno,
      placa: b.placa,
      sede: b.sede,
      capacidad: b.capacidad,
      activo: b.activo,
    })),
  };
}

export function mockManifiesto(fecha: string): ManifiestoPasajero[] {
  return [
    {
      boletoId: 1,
      viajeId: 101,
      fechaViaje: fecha,
      horaSalida: '06:00:00',
      origen: 'Bluefields',
      destino: 'Managua',
      busNumeroInterno: 'W-01',
      busPlaca: 'NI-1001',
      numeroAsiento: 1,
      pasajeroNombre: 'María López',
      pasajeroCedula: '001-120890-0001A',
      pasajeroTelefono: '8888-1111',
      codigoVenta: 'VT-DEMO-001',
      operadorNombre: 'Cajero Wendelyn',
      estadoBoleto: 'VENDIDO',
      esMenor: false,
    },
    {
      boletoId: 2,
      viajeId: 101,
      fechaViaje: fecha,
      horaSalida: '06:00:00',
      origen: 'Bluefields',
      destino: 'Managua',
      busNumeroInterno: 'W-01',
      busPlaca: 'NI-1001',
      numeroAsiento: 2,
      pasajeroNombre: 'Carlos Meza (menor)',
      pasajeroCedula: '001-150512-0002B',
      pasajeroTelefono: null,
      codigoVenta: 'VT-DEMO-001',
      operadorNombre: 'Cajero Wendelyn',
      estadoBoleto: 'VENDIDO',
      esMenor: true,
    },
    {
      boletoId: 3,
      viajeId: 101,
      fechaViaje: fecha,
      horaSalida: '06:00:00',
      origen: 'Bluefields',
      destino: 'Managua',
      busNumeroInterno: 'W-01',
      busPlaca: 'NI-1001',
      numeroAsiento: 5,
      pasajeroNombre: 'Ana Jarquín',
      pasajeroCedula: '001-080785-0003C',
      pasajeroTelefono: '7777-2222',
      codigoVenta: 'VT-DEMO-002',
      operadorNombre: 'Cajero Wendelyn',
      estadoBoleto: 'VENDIDO',
      esMenor: false,
    },
  ];
}

export function mockOcupacion(fecha: string): OcupacionViaje[] {
  return mockViajesOperador(fecha).map((v) => {
    const vendidos = 50 - v.asientosDisponibles;
    return {
      viajeId: v.id,
      fecha: v.fecha,
      horaSalida: v.horaSalida,
      origen: v.origen,
      destino: v.destino,
      busNumeroInterno: v.busNumeroInterno,
      busPlaca: mockBuses.find((b) => b.id === v.busId)?.placa ?? '',
      capacidadTotal: 50,
      asientosVendidos: vendidos,
      asientosReservados: 0,
      asientosDisponibles: v.asientosDisponibles,
      porcentajeOcupacion: Math.round((vendidos / 50) * 100),
    };
  });
}

export function mockIngresos(desde: string, hasta: string): IngresosReporte {
  return {
    desde,
    hasta,
    resumen: {
      totalIngresos: 12600,
      subtotalBoletos: 11900,
      subtotalEquipaje: 700,
      cantidadVentas: 8,
      cantidadBoletos: 34,
      ticketPromedio: 1575,
    },
    porDia: [
      {
        fecha: desde,
        totalIngresos: 6300,
        subtotalBoletos: 5950,
        subtotalEquipaje: 350,
        cantidadVentas: 4,
        cantidadBoletos: 17,
      },
    ],
    porViaje: mockViajesOperador(fechaHoyIso()).map((v) => ({
      viajeId: v.id,
      fecha: v.fecha,
      horaSalida: v.horaSalida,
      origen: v.origen,
      destino: v.destino,
      busNumeroInterno: v.busNumeroInterno,
      totalIngresos: v.id === 101 ? 4200 : 2100,
      subtotalBoletos: v.id === 101 ? 4000 : 2000,
      subtotalEquipaje: v.id === 101 ? 200 : 100,
      cantidadVentas: v.id === 101 ? 3 : 2,
      cantidadBoletos: v.id === 101 ? 12 : 6,
    })),
    porCajero: [
      {
        operadorId: 2,
        operadorNombre: 'Cajero Wendelyn',
        sede: 'Bluefields',
        totalIngresos: 8400,
        subtotalBoletos: 8000,
        subtotalEquipaje: 400,
        cantidadVentas: 5,
        cantidadBoletos: 22,
      },
    ],
    porTerminal: [
      { terminal: 'Bluefields', totalIngresos: 8400, cantidadVentas: 5, cantidadBoletos: 22 },
      { terminal: 'Managua', totalIngresos: 4200, cantidadVentas: 3, cantidadBoletos: 12 },
    ],
    ventas: [
      {
        ventaId: 1,
        codigo: 'VT-DEMO-001',
        fechaVenta: `${desde}T08:15:00`,
        total: 850,
        subtotalBoletos: 700,
        subtotalEquipaje: 150,
        cantidadBoletos: 2,
        operadorNombre: 'Cajero Wendelyn',
        operadorSede: 'Bluefields',
        origen: 'Bluefields',
        destino: 'Managua',
        fechaViaje: desde,
        horaSalida: '06:00:00',
      },
    ],
  };
}

export function mockVentaResponse(viajeId: number, asientoIds: number[]): VentaResponse {
  const viaje = mockViajesOperador(fechaHoyIso()).find((v) => v.id === viajeId);
  const tarifa = viaje?.tarifa ?? 350;
  const n = asientoIds.length;

  return {
    id: 9001,
    codigo: `VT-MOCK-${Date.now().toString(36).toUpperCase()}`,
    viajeId,
    compradorNombre: 'Pasajero Demo',
    compradorCedula: '001-000000-0000X',
    compradorTelefono: '8888-0000',
    numerosAsiento: asientoIds.map((_, i) => i + 1),
    subtotalBoletos: tarifa * n,
    subtotalEquipaje: 0,
    total: tarifa * n,
  };
}

export const MOCK_DELAY_MS = 120;
