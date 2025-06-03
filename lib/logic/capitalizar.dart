String capitalizarPrimeraLetra(String texto) {
  if (texto.isEmpty) {
    return texto;
  }
  return texto[0].toUpperCase() + texto.substring(1);
}