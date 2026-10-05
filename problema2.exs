# ============================================================
# Problema 2
#
#   void function(int n) {
#       if (n <= 1) return;
#       int i, j;
#       for (i = 1; i <= n; i++)
#           for (j = 1; j <= n; j++) {
#               printf("Sequence\n");
#               break;
#           }
#   }
#
# Complejidad: O(n)
#
# Nota: el printf se cambio por un contador. Imprimir en pantalla
# un millon de veces mide la velocidad de la consola, no la del
# algoritmo, y el numero de vueltas es exactamente el mismo.
# ============================================================

Code.require_file("comun.exs", __DIR__)

defmodule Problema2 do
  # ------------------------------------------------------------
  # Bucle de adentro: entra una sola vez y se sale de inmediato
  # por el break. Si j ya paso de n no entra nada.
  # ------------------------------------------------------------
  defp bucle_j(j, n, contador) when j > n, do: contador
  defp bucle_j(_j, _n, contador), do: contador + 1

  # ------------------------------------------------------------
  # Bucle de afuera: i = 1, 2, 3, ... hasta n
  # ------------------------------------------------------------
  defp bucle_i(i, n, contador) when i > n, do: contador
  defp bucle_i(i, n, contador), do: bucle_i(i + 1, n, bucle_j(1, n, contador))

  # ------------------------------------------------------------
  # Programa completo. Con n <= 1 se sale de una vez.
  # ------------------------------------------------------------
  def ejecutar(n) when n <= 1, do: 0
  def ejecutar(n), do: bucle_i(1, n, 0)

  # ------------------------------------------------------------
  # Cuantas veces se imprime "Sequence": una por cada vuelta del
  # bucle de afuera, porque el de adentro siempre hace break
  # ------------------------------------------------------------
  def iteraciones(n) when n <= 1, do: 0
  def iteraciones(n), do: n
end

# ------------------------------------------------------------
# Aqui todos los tamanos se corren de verdad, porque el programa
# es lineal y hasta n = 1,000,000 termina al instante
# ------------------------------------------------------------
medidos = Comun.filtrar(Comun.tamanos())
estimados = Comun.tamanos() -- medidos

IO.puts("")
IO.puts("Problema 2  -  bucle con break  -  O(n)")
IO.puts("Midiendo...")

filas = Comun.perfilar(&Problema2.ejecutar/1, &Problema2.iteraciones/1, medidos, estimados)

Comun.imprimir_tabla("Problema 2: tamano de entrada vs tiempo", filas)
Comun.guardar_csv("problema2", filas)
Comun.guardar_grafica("problema2", "Problema 2  -  O(n)", filas)
