import type { Bus, Empresa, ParadaRuta, UsuarioPerfil, VentaRequest, ViajeOperador } from '@/shared/api/types';
import {
  MOCK_DELAY_MS,
  fechaHoyIso,
  mockBuses,
  mockDetalleCooperativa,
  mockDetalleViajeOperador,
  mockDetalleViajePublico,
  mockEmpresas,
  mockIngresos,
  mockManifiesto,
  mockOcupacion,
  mockOperadores,
  mockParadas,
  mockPerfil,
  mockResumenPlataforma,
  mockVentaResponse,
  mockViajesDisponibles,
  mockViajesOperador,
} from './mockData';

function delay(ms = MOCK_DELAY_MS): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function parsePath(fullPath: string): { pathname: string; searchParams: URLSearchParams } {
  const qIndex = fullPath.indexOf('?');
  const pathname = qIndex >= 0 ? fullPath.slice(0, qIndex) : fullPath;
  const query = qIndex >= 0 ? fullPath.slice(qIndex + 1) : '';
  return { pathname, searchParams: new URLSearchParams(query) };
}

function matchId(pathname: string, prefix: string): number | null {
  const m = pathname.match(new RegExp(`^${prefix.replace(/\//g, '\\/')}(\\d+)`));
  return m ? Number(m[1]) : null;
}

function filterViajes(empresaId: number | null, fecha: string, origen?: string | null): ViajeOperador[] {
  let list = mockViajesOperador(fecha);
  if (empresaId != null) list = list.filter((v) => v.empresaId === empresaId);
  if (origen) list = list.filter((v) => v.origen === origen);
  return list;
}

function filterBuses(empresaId: number | null, sede?: string | null): Bus[] {
  let list = mockBuses;
  if (empresaId != null) list = list.filter((b) => b.empresaId === empresaId);
  if (sede) list = list.filter((b) => b.sede === sede);
  return list;
}

export async function handleMockRequest<T>(fullPath: string, options: RequestInit = {}): Promise<T> {
  await delay();

  const method = (options.method ?? 'GET').toUpperCase();
  const { pathname, searchParams } = parsePath(fullPath);
  const body = options.body ? (JSON.parse(options.body as string) as Record<string, unknown>) : null;

  // --- Auth / perfil ---
  if (pathname === '/api/usuarios/me') {
    return mockPerfil as T;
  }

  if (pathname === '/api/usuarios') {
    const empresaId = searchParams.get('empresaId');
    const list = empresaId
      ? mockOperadores.filter((o) => o.empresaId === Number(empresaId))
      : mockOperadores;
    return list as T;
  }

  if (pathname.startsWith('/api/usuarios/') && method === 'PATCH') {
    const id = matchId(pathname, '/api/usuarios/');
    const user = mockOperadores.find((o) => o.id === id) ?? mockPerfil;
    return { ...user, ...body } as T;
  }

  if (pathname === '/api/usuarios' && method === 'POST') {
    const nuevo: UsuarioPerfil = {
      id: 99,
      empresaId: Number(body?.empresaId ?? 1),
      empresaNombre: 'Wendelyn Transporte',
      nombreUsuario: String(body?.nombreUsuario ?? 'nuevo.operador'),
      emailLogin: String(body?.email ?? 'nuevo@demo.com'),
      nombreCompleto: String(body?.nombreCompleto ?? 'Operador Demo'),
      sede: String(body?.sede ?? 'Bluefields'),
      activo: true,
      roles: (body?.roles as string[]) ?? ['CAJERO'],
    };
    return nuevo as T;
  }

  // --- Empresas ---
  if (pathname === '/api/empresas') {
    if (method === 'POST') {
      const nueva: Empresa = {
        id: mockEmpresas.length + 1,
        nombre: String(body?.nombre ?? 'Cooperativa Demo'),
        telefono: (body?.telefono as string) ?? null,
        correo: (body?.correo as string) ?? null,
        tarifaEquipajeExtra: Number(body?.tarifaEquipajeExtra ?? 150),
        logoUrl: (body?.logoUrl as string) ?? null,
        activo: true,
      };
      return nueva as T;
    }
    return mockEmpresas as T;
  }

  if (pathname === '/api/empresas/mi-empresa') {
    return mockEmpresas[0] as T;
  }

  if (pathname === '/api/empresas/resumen-plataforma') {
    return mockResumenPlataforma as T;
  }

  const empresaDetalleId = matchId(pathname, '/api/empresas/');
  if (empresaDetalleId != null && pathname.endsWith('/detalle-plataforma')) {
    return mockDetalleCooperativa(empresaDetalleId) as T;
  }

  if (empresaDetalleId != null && pathname.endsWith('/desactivar') && method === 'PATCH') {
    return { message: 'Cooperativa desactivada (demo)', id: String(empresaDetalleId) } as T;
  }

  if (empresaDetalleId != null && method === 'PUT') {
    const emp = mockEmpresas.find((e) => e.id === empresaDetalleId) ?? mockEmpresas[0];
    return { ...emp, ...body } as T;
  }

  if (empresaDetalleId != null) {
    const emp = mockEmpresas.find((e) => e.id === empresaDetalleId);
    if (emp) return emp as T;
  }

  // --- Buses ---
  if (pathname === '/api/buses/mi-empresa') {
    return filterBuses(1, searchParams.get('sede')) as T;
  }

  if (pathname === '/api/buses' && method === 'GET') {
    const empresaId = searchParams.get('empresaId');
    return filterBuses(empresaId ? Number(empresaId) : null, searchParams.get('sede')) as T;
  }

  if (pathname === '/api/buses' && method === 'POST') {
    const bus: Bus = {
      id: mockBuses.length + 1,
      empresaId: Number(body?.empresaId ?? 1),
      numeroInterno: String(body?.numeroInterno ?? 'D-01'),
      placa: String(body?.placa ?? 'NI-9999'),
      capacidad: Number(body?.capacidad ?? 50),
      filas: 13,
      activo: true,
      fotoUrl: (body?.fotoUrl as string) ?? null,
      sede: String(body?.sede ?? 'Bluefields'),
    };
    return bus as T;
  }

  const busId = matchId(pathname, '/api/buses/');
  if (busId != null && pathname.includes('/asientos/') && method === 'PUT') {
    const asientoId = matchId(pathname, '/asientos/');
    const bus = mockBuses.find((b) => b.id === busId);
    const asiento = bus?.asientos?.find((a) => a.id === asientoId);
    return { ...asiento, ...body, id: asientoId ?? 1 } as T;
  }

  if (busId != null && method === 'PUT') {
    const bus = mockBuses.find((b) => b.id === busId) ?? mockBuses[0];
    return { ...bus, ...body } as T;
  }

  if (busId != null) {
    const bus = mockBuses.find((b) => b.id === busId);
    if (bus) return bus as T;
  }

  // --- Viajes ---
  if (pathname === '/api/viajes/mi-empresa') {
    const fecha = searchParams.get('fecha') ?? fechaHoyIso();
    return filterViajes(1, fecha, searchParams.get('origen')) as T;
  }

  if (pathname === '/api/viajes' && method === 'GET') {
    const fecha = searchParams.get('fecha') ?? fechaHoyIso();
    const empresaId = searchParams.get('empresaId');
    return filterViajes(empresaId ? Number(empresaId) : null, fecha, searchParams.get('origen')) as T;
  }

  if (pathname === '/api/viajes' && method === 'POST') {
    const fecha = String(body?.fecha ?? fechaHoyIso());
    const viaje: ViajeOperador = {
      id: 900 + mockViajesOperador(fecha).length,
      empresaId: Number(body?.empresaId ?? 1),
      empresaNombre: mockEmpresas.find((e) => e.id === Number(body?.empresaId))?.nombre ?? 'Wendelyn Transporte',
      busId: Number(body?.busId ?? 1),
      busNumeroInterno: mockBuses.find((b) => b.id === Number(body?.busId))?.numeroInterno ?? 'W-01',
      origen: String(body?.origen ?? 'Bluefields'),
      destino: String(body?.destino ?? 'Managua'),
      fecha,
      horaSalida: String(body?.horaSalida ?? '08:00:00'),
      tarifa: Number(body?.tarifa ?? 350),
      tarifaEquipajeExtra: Number(body?.tarifaEquipajeExtra ?? 150),
      estado: 'PROGRAMADO',
      asientosDisponibles: 50,
    };
    return viaje as T;
  }

  const viajeId = matchId(pathname, '/api/viajes/');
  if (viajeId != null && pathname.endsWith('/detalle-operador')) {
    const detalle = mockDetalleViajeOperador(viajeId);
    if (!detalle) throw new Error(`Viaje ${viajeId} no encontrado (demo)`);
    return detalle as T;
  }

  if (viajeId != null && pathname.endsWith('/cancelar') && method === 'PATCH') {
    const v = mockViajesOperador(fechaHoyIso()).find((x) => x.id === viajeId);
    return { ...v, estado: 'CANCELADO' } as T;
  }

  if (viajeId != null && method === 'PUT') {
    const v = mockViajesOperador(fechaHoyIso()).find((x) => x.id === viajeId);
    return { ...v, ...body } as T;
  }

  // --- Consulta pública ---
  if (pathname === '/api/publico/viajes' && method === 'GET') {
    const fecha = searchParams.get('fecha') ?? fechaHoyIso();
    const origen = searchParams.get('origen');
    const destino = searchParams.get('destino');
    let list = mockViajesDisponibles(fecha);
    if (origen && destino) {
      list = list.filter(
        (v) =>
          mockViajesOperador(fecha).some(
            (o) => o.id === v.viajeId && o.origen === origen && o.destino === destino
          )
      );
    }
    return list as T;
  }

  const viajePublicoId = matchId(pathname, '/api/publico/viajes/');
  if (viajePublicoId != null) {
    const detalle = mockDetalleViajePublico(viajePublicoId);
    if (!detalle) throw new Error(`Viaje ${viajePublicoId} no encontrado (demo)`);
    return detalle as T;
  }

  if (pathname.startsWith('/api/externo/tarifa-referencia-usd')) {
    const monto = Number(searchParams.get('monto') ?? 350);
    return { equivalenteUsd: Math.round((monto / 36.5) * 100) / 100 } as T;
  }

  // --- Ventas / pasajeros ---
  if (pathname === '/api/ventas' && method === 'POST') {
    const req = body as unknown as VentaRequest;
    return mockVentaResponse(req.viajeId, req.viajeAsientoIds) as T;
  }

  if (pathname === '/api/pasajeros/manifiesto') {
    const fecha = searchParams.get('fecha') ?? fechaHoyIso();
    let list = mockManifiesto(fecha);
    const viajeId = searchParams.get('viajeId');
    const busId = searchParams.get('busId');
    if (viajeId) list = list.filter((p) => p.viajeId === Number(viajeId));
    if (busId) {
      const bus = mockBuses.find((b) => b.id === Number(busId));
      if (bus) list = list.filter((p) => p.busNumeroInterno === bus.numeroInterno);
    }
    return list as T;
  }

  if (pathname === '/api/reservas-excepcionales' && method === 'POST') {
    return { id: 5001, numeroAsiento: 25 } as T;
  }

  // --- Reportes ---
  if (pathname === '/api/reportes/ocupacion') {
    const fecha = searchParams.get('fecha') ?? fechaHoyIso();
    let list = mockOcupacion(fecha);
    const empresaId = searchParams.get('empresaId');
    if (empresaId) {
      const ids = mockViajesOperador(fecha)
        .filter((v) => v.empresaId === Number(empresaId))
        .map((v) => v.id);
      list = list.filter((o) => ids.includes(o.viajeId));
    }
    return list as T;
  }

  if (pathname === '/api/reportes/ingresos') {
    const desde = searchParams.get('desde') ?? fechaHoyIso();
    const hasta = searchParams.get('hasta') ?? fechaHoyIso();
    return mockIngresos(desde, hasta) as T;
  }

  // --- Paradas ---
  if (pathname === '/api/paradas' && method === 'GET') {
    return mockParadas as T;
  }

  if (pathname === '/api/paradas' && method === 'POST') {
    const parada: ParadaRuta = {
      id: mockParadas.length + 1,
      nombre: String(body?.nombre ?? 'Parada demo'),
      orden: mockParadas.length + 1,
      minutosDesdeSalida: Number(body?.minutosDesdeSalida ?? 0),
      horaEstimada: '08:00:00',
      latitud: Number(body?.latitud ?? 12.0),
      longitud: Number(body?.longitud ?? -86.0),
    };
    return parada as T;
  }

  const paradaId = matchId(pathname, '/api/paradas/');
  if (paradaId != null && method === 'PUT') {
    const p = mockParadas.find((x) => x.id === paradaId) ?? mockParadas[0];
    return { ...p, ...body } as T;
  }

  if (paradaId != null && method === 'DELETE') {
    return undefined as T;
  }

  throw new Error(`[Modo demo] Ruta no simulada: ${method} ${pathname}`);
}
