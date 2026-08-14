export interface ViajeDisponible {
  viajeId: number;
  empresaNombre: string;
  empresaLogoUrl?: string | null;
  horaSalida: string;
  asientosDisponibles: number;
  capacidadTotal: number;
  tarifa: number;
}

export interface ParadaRuta {
  id: number;
  nombre: string;
  orden: number;
  minutosDesdeSalida?: number;
  horaEstimada: string | null;
  latitud: number | null;
  longitud: number | null;
}

export interface AsientoViaje {
  viajeAsientoId: number;
  numero: number;
  fila: number;
  posicion: 'VENTANA' | 'PASILLO' | 'TRASERA_1' | 'TRASERA_2' | 'TRASERA_3' | 'TRASERA_4' | 'TRASERA_5';
  estado: 'DISPONIBLE' | 'VENDIDO' | 'CANCELADO' | 'RESERVADO_EXCEPCIONAL';
}

export interface DetalleViaje {
  viajeId: number;
  empresaNombre: string;
  empresaLogoUrl?: string | null;
  busNumeroInterno?: string | null;
  busFotoUrl?: string | null;
  origen: string;
  destino: string;
  fecha: string;
  horaSalida: string;
  tarifa: number;
  tarifaEquipajeExtra: number;
  asientosDisponibles: number;
  asientos: AsientoViaje[];
  paradas?: ParadaRuta[];
}

export interface Empresa {
  id: number;
  nombre: string;
  telefono: string | null;
  correo: string | null;
  tarifaEquipajeExtra: number;
  logoUrl?: string | null;
  activo: boolean;
}

export interface Bus {
  id: number;
  empresaId: number;
  numeroInterno: string;
  placa: string;
  capacidad: number;
  filas: number;
  activo: boolean;
  fotoUrl?: string | null;
  sede: string;
  asientos?: AsientoBus[];
}

export interface AsientoBus {
  id: number;
  numero: number;
  fila: number;
  posicion: AsientoViaje['posicion'];
}

export interface ViajeOperador {
  id: number;
  empresaId: number;
  empresaNombre: string;
  busId: number;
  busNumeroInterno: string;
  origen: string;
  destino: string;
  fecha: string;
  horaSalida: string;
  tarifa: number;
  tarifaEquipajeExtra: number | null;
  estado: string;
  asientosDisponibles: number;
}

export interface VentaResponse {
  id: number;
  codigo: string;
  viajeId: number;
  compradorNombre: string;
  compradorCedula: string;
  compradorTelefono?: string;
  numerosAsiento: number[];
  subtotalBoletos: number;
  subtotalEquipaje: number;
  total: number;
}

export interface VentaRequest {
  viajeId: number;
  compradorNombre: string;
  compradorCedula: string;
  compradorTelefono?: string;
  viajeAsientoIds: number[];
  pasajeros?: {
    viajeAsientoId: number;
    pasajeroNombre: string;
    pasajeroCedula: string;
    esMenor?: boolean;
    edad?: number;
  }[];
  equipajeExtra?: { cantidad: number; montoUnitario?: number };
}

export interface UsuarioPerfil {
  id: number;
  empresaId: number | null;
  empresaNombre: string | null;
  nombreUsuario: string;
  emailLogin?: string | null;
  nombreCompleto: string;
  sede: string | null;
  activo?: boolean;
  roles: string[];
}

export interface DetalleCooperativa {
  empresa: Empresa;
  metricas: {
    busesActivos: number;
    busesInactivos: number;
    adminsActivos: number;
    adminsInactivos: number;
    cajerosActivos: number;
    cajerosInactivos: number;
    viajesHoy: number;
    boletosVendidosHoy: number;
  };
  operadores: {
    id: number;
    nombreUsuario: string;
    emailLogin: string;
    nombreCompleto: string;
    sede: string | null;
    activo: boolean;
    roles: string[];
  }[];
  buses: {
    id: number;
    numeroInterno: string;
    placa: string;
    sede: string;
    capacidad: number;
    activo: boolean;
  }[];
}

export interface ResumenEmpresa {
  id: number;
  nombre: string;
  activo: boolean;
  busesActivos: number;
  operadoresActivos: number;
  viajesHoy: number;
  boletosVendidosHoy: number;
}

export interface ManifiestoPasajero {
  boletoId: number;
  viajeId: number;
  fechaViaje: string;
  horaSalida: string;
  origen: string;
  destino: string;
  busNumeroInterno: string;
  busPlaca: string;
  numeroAsiento: number;
  pasajeroNombre: string;
  pasajeroCedula: string;
  pasajeroTelefono: string | null;
  codigoVenta: string;
  operadorNombre: string;
  estadoBoleto: string;
  esMenor: boolean;
}

export interface OcupacionViaje {
  viajeId: number;
  fecha: string;
  horaSalida: string;
  origen: string;
  destino: string;
  busNumeroInterno: string;
  busPlaca: string;
  capacidadTotal: number;
  asientosVendidos: number;
  asientosReservados: number;
  asientosDisponibles: number;
  porcentajeOcupacion: number;
}

export interface IngresosResumen {
  totalIngresos: number;
  subtotalBoletos: number;
  subtotalEquipaje: number;
  cantidadVentas: number;
  cantidadBoletos: number;
  ticketPromedio: number;
}

export interface IngresosPorDia {
  fecha: string;
  totalIngresos: number;
  subtotalBoletos: number;
  subtotalEquipaje: number;
  cantidadVentas: number;
  cantidadBoletos: number;
}

export interface IngresosPorViaje {
  viajeId: number;
  fecha: string;
  horaSalida: string;
  origen: string;
  destino: string;
  busNumeroInterno: string;
  totalIngresos: number;
  subtotalBoletos: number;
  subtotalEquipaje: number;
  cantidadVentas: number;
  cantidadBoletos: number;
}

export interface IngresosPorCajero {
  operadorId: number;
  operadorNombre: string;
  sede: string;
  totalIngresos: number;
  subtotalBoletos: number;
  subtotalEquipaje: number;
  cantidadVentas: number;
  cantidadBoletos: number;
}

export interface IngresosPorTerminal {
  terminal: string;
  totalIngresos: number;
  cantidadVentas: number;
  cantidadBoletos: number;
}

export interface IngresosVentaDetalle {
  ventaId: number;
  codigo: string;
  fechaVenta: string;
  total: number;
  subtotalBoletos: number;
  subtotalEquipaje: number;
  cantidadBoletos: number;
  operadorNombre: string;
  operadorSede: string;
  origen: string;
  destino: string;
  fechaViaje: string;
  horaSalida: string;
}

export interface IngresosReporte {
  desde: string;
  hasta: string;
  resumen: IngresosResumen;
  porDia: IngresosPorDia[];
  porViaje: IngresosPorViaje[];
  porCajero: IngresosPorCajero[];
  porTerminal: IngresosPorTerminal[];
  ventas: IngresosVentaDetalle[];
}
