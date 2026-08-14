const ciudadesCorredor = ['Bluefields', 'Managua'];

typedef CiudadCorredor = String;

String destinoOpuesto(String origen) {
  return origen == 'Bluefields' ? 'Managua' : 'Bluefields';
}
