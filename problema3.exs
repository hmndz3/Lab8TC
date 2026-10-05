# ============================================================
# Problema 3
#
#   void function(int n) {
#       int i, j;
#       for (i = 1; i <= n/3; i++)
#           for (j = 1; j <= n; j += 4)
#               printf("Sequence\n");
#   }
#
# Complejidad: O(n^2)
#
# Nota: el printf se cambio por un contador. Con n = 1,000,000
# serian mas de 83 mil millones de impresiones; lo que interesa
# medir es el trabajo de los bucles, no la consola.
# ============================================================

Code.require_file("comun.exs", __DIR__)

defmodule Problema3 do
  # ------------------------------------------------------------
  # Bucle de adentro: j = 1, 5, 9, 13, ... mientras j <= n
  # ------------------------------------------------------------
  defp bucle_j(j, n, contador) when j > n, do: contador
  defp bucle_j(j, n, contador), do: bucle_j(j + 4, n, contador + 1)

  # ------------------------------------------------------------
  # Bucle de afuera: i = 1, 2, 3, ... hasta n/3
  # ------------------------------------------------------------
  defp bucle_i(i, limite, _n, contador) when i > limite, do: contador

  defp bucle_i(i, limite, n, contador) do
    bucle_i(i + 1, limite, n, bucle_j(1, n, contador))
  end

  # ------------------------------------------------------------
  # Programa completo
  # ------------------------------------------------------------
  def ejecutar(n), do: bucle_i(1, div(n, 3), n, 0)

  # ------------------------------------------------------------
  # Cuantas veces se imprime "Sequence": (n/3) vueltas de afuera
  # por (n/4) vueltas de adentro
  # ------------------------------------------------------------
  def iteraciones(n) do
    vueltas_i = div(n, 3)
    vueltas_j = div(n - 1, 4) + 1
    vueltas_i * vueltas_j
  end
end

# ------------------------------------------------------------
# Todos los tamanos se corren de verdad. El mas pesado es
# n = 1,000,000, que tarda varios minutos.
# ------------------------------------------------------------
medidos = Comun.filtrar(Comun.tamanos())
estimados = Comun.tamanos() -- medidos

IO.puts("")
IO.puts("Problema 3  -  dos bucles anidados  -  O(n^2)")
IO.puts("Midiendo...  (el ultimo tamano tarda varios minutos)")

filas = Comun.perfilar(&Problema3.ejecutar/1, &Problema3.iteraciones/1, medidos, estimados)

Comun.imprimir_tabla("Problema 3: tamano de entrada vs tiempo", filas)
Comun.guardar_csv("problema3", filas)
Comun.guardar_grafica("problema3", "Problema 3  -  O(n^2)", filas)
