export const CIUDADES_CORREDOR = ['Bluefields', 'Managua'] as const;

export type CiudadCorredor = (typeof CIUDADES_CORREDOR)[number];

export function destinoOpuesto(origen: CiudadCorredor): CiudadCorredor {
  return origen === 'Bluefields' ? 'Managua' : 'Bluefields';
}
