/// Ésta es la clase principal que nos sirve para representar el estado del juego.
/// Tiene la lista de torres, el costo real, la heurística y una referencia al padre.
/// Se utiliza dentro del algortimo para reconstruír la ruta al final.
class EstadoHanoi {
  /// 'torres[i]' indica en qué poste se encuentra el disco i.
  final List<int> torres;

  /// 'costoReal' es la cantidad de movimientos realizados desde el estado inicial.
  final int costoReal;

  /// 'heuristica' es la estimación de movimientos restantes,
  /// calculada como la suma de (2 - torres[i]).
  final int heuristica;

  /// 'padre' referencia al estado anterior, para reconstruir la trayectoria.
  final EstadoHanoi? padre;

  EstadoHanoi({
    required this.torres,
    required this.costoReal,
    required this.heuristica,
    this.padre,
  });

  /// f = costoReal + heuristica (criterio principal de A*).
  int get f => costoReal + heuristica;

  @override
  bool operator ==(Object other) {
    if (other is! EstadoHanoi) return false;
    if (other.torres.length != torres.length) return false;
    for (int i = 0; i < torres.length; i++) {
      if (other.torres[i] != torres[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    // Calculamos un hash combinando las posiciones de los discos.
    int resultado = 17;
    for (int valor in torres) {
      resultado = 37 * resultado + valor;
    }
    return resultado;
  }
}

/// Esta función nos ayuda a calcular la heurístika de un estado dado.
/// Se basa en sumarle (2 - poste) por cada disco. Con eso estimamos
/// cuanto falta pa' llegar todos al poste 2.
int calcularHeuristica(List<int> torres) {
  int suma = 0;
  for (int poste in torres) {
    suma += (2 - poste);
  }
  return suma;
}

/// Aquí generamos todos los posibles movimientos sucesores, o sea,
/// las jugadas que se pueden hacer desde un estado actual. Revisamos
/// cual disco esta en la cima de cada poste y vemos a cual poste lo
/// podriamos mover legalmente.
List<List<int>> generarSucesores(List<int> estadoActual) {
  int n = estadoActual.length;
  List<List<int>> sucesores = [];

  // Identificamos el disco superior en cada poste (si existe).
  List<int?> discoSuperior = [null, null, null];
  for (int disco = 0; disco < n; disco++) {
    int posteActual = estadoActual[disco];
    if (discoSuperior[posteActual] == null) {
      discoSuperior[posteActual] = disco;
    }
  }

  // Intentar mover cada disco superior a los demás postes
  for (int origen = 0; origen < 3; origen++) {
    int? discoMovible = discoSuperior[origen];
    if (discoMovible == null) continue; // no hay disco que mover en este poste

    // Probar mover a cada uno de los otros postes
    for (int destino = 0; destino < 3; destino++) {
      if (destino == origen) continue; // no mover al mismo poste

      // Validar la jugada:
      // Se puede mover si el poste destino está vacío
      // o si el disco del destino es de mayor índice (más grande).
      bool mover = false;
      int? discoEncimaDestino = discoSuperior[destino];
      if (discoEncimaDestino == null) {
        mover = true;
      } else {
        if (discoMovible < discoEncimaDestino) {
          mover = true;
        }
      }

      if (mover) {
        // Creamos un nuevo estado (lista) con ese movimiento
        List<int> nuevoEstado = List<int>.from(estadoActual);
        nuevoEstado[discoMovible] = destino;
        sucesores.add(nuevoEstado);
      }
    }
  }

  return sucesores;
}

/// En esta funcion, tomamos un EstadoHanoi y generamos sus sucesores como objetos EstadoHanoi
/// calculando su costo real (g) y su heurística (h). Tambien se asigna el padre
/// para luego reconstruir la ruta.
List<EstadoHanoi> expandirEstado(EstadoHanoi actual) {
  // 1. Obtener la lista de sucesores como listas de enteros
  List<List<int>> sucesoresListas = generarSucesores(actual.torres);

  // 2. Transformarlos en objetos 'EstadoHanoi'
  List<EstadoHanoi> nuevos = [];
  for (var sucesor in sucesoresListas) {
    int nuevoCosto = actual.costoReal + 1;
    int nuevaHeuristica = calcularHeuristica(sucesor);

    EstadoHanoi estadoSucesor = EstadoHanoi(
      torres: sucesor,
      costoReal: nuevoCosto,
      heuristica: nuevaHeuristica,
      padre: actual,
    );
    nuevos.add(estadoSucesor);
  }

  return nuevos;
}

/// Esta función será la que determina si ya llegamos al objetivo.
/// Queremos que todos los discos esten en el poste 2, así que
/// si esto se cumple retornamos true, si no, false.
bool esObjetivo(List<int> torres) {
  for (int poste in torres) {
    if (poste != 2) return false;
  }
  return true;
}

/// Este bloque es el corazon del algoritmo A*. Mantenemos una lista de estados abiertos
/// y buscamos el que tenga el menor f = g + h. Luego expandimos hasta encontrar el estado meta
/// llamando a la función objetivo para ver si ya llegamos.
List<EstadoHanoi> aStarHanoi(int numeroDiscos) {
  // Estado inicial: todos en poste 0
  List<int> inicial = List<int>.filled(numeroDiscos, 0);

  // Creamos el objeto EstadoHanoi inicial
  int hInicial = calcularHeuristica(inicial);
  EstadoHanoi inicio = EstadoHanoi(
    torres: inicial,
    costoReal: 0,
    heuristica: hInicial,
    padre: null,
  );

  // Estructura 'abiertos' para expandir
  List<EstadoHanoi> abiertos = [];
  abiertos.add(inicio);

  // Mapa 'visitados' que guarda el menor costoReal conocido para cada estado
  Map<EstadoHanoi, int> visitados = {};
  visitados[inicio] = 0;

  while (abiertos.isNotEmpty) {
    // 1. Buscar el estado con menor f (costoReal + heuristica) en 'abiertos'
    int indiceMejor = 0;
    int mejorF = abiertos[0].f;
    for (int i = 1; i < abiertos.length; i++) {
      int fActual = abiertos[i].f;
      if (fActual < mejorF) {
        indiceMejor = i;
        mejorF = fActual;
      }
    }

    // 2. Extraer ese estado
    EstadoHanoi actual = abiertos.removeAt(indiceMejor);

    // 3. Revisar si es el objetivo
    if (esObjetivo(actual.torres)) {
      // Reconstruir la ruta y regresar
      return _reconstruirRuta(actual);
    }

    // 4. Expandir
    List<EstadoHanoi> sucesores = expandirEstado(actual);
    for (var st in sucesores) {
      int costoAnterior = visitados[st] ?? 999999999;
      if (st.costoReal < costoAnterior) {
        visitados[st] = st.costoReal;
        abiertos.add(st);
      }
    }
  }

  // Si no se encuentra solución, devolvemos lista vacía
  return [];
}

/// Con esta función reconstruimos la ruta final. Empezamos en el estado
/// meta y vamos retrocediendo con la referencia 'padre' hasta el estado inicial.
List<EstadoHanoi> _reconstruirRuta(EstadoHanoi estadoFinal) {
  List<EstadoHanoi> camino = [];
  EstadoHanoi? actual = estadoFinal;
  while (actual != null) {
    camino.add(actual);
    actual = actual.padre;
  }
  return camino.reversed.toList();
}

/// Esta función imprime el estado de las torres, mostrando que discos
/// estan en cada poste.
Future<void> imprimirEstadoHanoi(List<int> torres) async {
  int n = torres.length;
  List<int> poste0 = [];
  List<int> poste1 = [];
  List<int> poste2 = [];

  // Recorremos de disco más grande (n-1) a más pequeño (0)
  for (int disco = n - 1; disco >= 0; disco--) {
    int p = torres[disco];
    if (p == 0) poste0.add(disco);
    if (p == 1) poste1.add(disco);
    if (p == 2) poste2.add(disco);
  }

  print("Poste 0: $poste0");
  print("Poste 1: $poste1");
  print("Poste 2: $poste2");
  print("----------------------------------");
  await Future.delayed(Duration(seconds: 2));
}

/// Esta es la función main, donde probamos todo lo anterior.
/// Aqui escogemos el numero de discos y llamamos al A*, luego
/// mostramos el resultado paso a paso.
Future<void> main() async {
  int numeroDiscos = 3; 
  List<EstadoHanoi> solucion = aStarHanoi(numeroDiscos);

  if (solucion.isEmpty) {
    print("No se encontró solución");
    return;
  }

  print("Se encontró solución en ${solucion.last.costoReal} movimientos.");
  for (int i = 0; i < solucion.length; i++) {
    EstadoHanoi paso = solucion[i];
    print(
        "Movimiento #$i (g=${paso.costoReal}, h=${paso.heuristica}, f=${paso.f})");
    await imprimirEstadoHanoi(paso.torres);
  }
}
