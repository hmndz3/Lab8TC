# ============================================================
# Problema 1
#
#   void function(int n) {
#       int i, j, k, counter = 0;
#       for (i = n/2; i <= n; i++)
#           for (j = 1; j+n/2 <= n; j++)
#               for (k = 1; k <= n; k = k*2)
#                   counter++;
#   }
#
# Complejidad: O(n^2 log n)
# ============================================================

Code.require_file("comun.exs", __DIR__)

defmodule Problema1 do
  # ------------------------------------------------------------
  # Bucle de adentro: k = 1, 2, 4, 8, ... mientras k <= n.
  # Cada vuelta suma uno al contador.
  # ------------------------------------------------------------
  defp bucle_k(k, n, contador) when k > n, do: contador
  defp bucle_k(k, n, contador), do: bucle_k(k * 2, n, contador + 1)

  # ------------------------------------------------------------
  # Bucle de en medio: j = 1, 2, 3, ... mientras j + n/2 <= n,
  # o sea mientras j no pase de n - n/2
  # ------------------------------------------------------------
  defp bucle_j(j, limite, _n, contador) when j > limite, do: contador

  defp bucle_j(j, limite, n, contador) do
    bucle_j(j + 1, limite, n, bucle_k(1, n, contador))
  end

  # ------------------------------------------------------------
  # Bucle de afuera: i arranca en n/2 y sube de uno en uno hasta n
  # ------------------------------------------------------------
  defp bucle_i(i, n, _limite, contador) when i > n, do: contador

  defp bucle_i(i, n, limite, contador) do
    bucle_i(i + 1, n, limite, bucle_j(1, limite, n, contador))
  end

  # ------------------------------------------------------------
  # Programa completo. Devuelve el valor final de counter.
  # ------------------------------------------------------------
  def ejecutar(n), do: bucle_i(div(n, 2), n, n - div(n, 2), 0)

  # ------------------------------------------------------------
  # Cuenta cuantas veces se ejecuta counter++ sin tener que correr
  # el programa: (n/2 + 1) * (n/2) * (log2(n) + 1)
  # ------------------------------------------------------------
  def iteraciones(n) do
    vueltas_i = n - div(n, 2) + 1
    vueltas_j = n - div(n, 2)
    vueltas_k = Comun.potencias_de_dos(n)
    vueltas_i * vueltas_j * vueltas_k
  end
end

# ------------------------------------------------------------
# Hasta n = 100,000 el programa se corre de verdad. Para
# n = 1,000,000 serian mas de 5 billones de iteraciones (unas 8
# horas de espera), asi que ese punto se proyecta usando el costo
# por iteracion que se midio en n = 100,000.
# ------------------------------------------------------------
medidos = Comun.filtrar(Enum.reject(Comun.tamanos(), &(&1 > 100_000)))
estimados = Comun.tamanos() -- medidos

IO.puts("")
IO.puts("Problema 1  -  tres bucles anidados  -  O(n^2 log n)")
IO.puts("Midiendo...")

filas = Comun.perfilar(&Problema1.ejecutar/1, &Problema1.iteraciones/1, medidos, estimados)

Comun.imprimir_tabla("Problema 1: tamano de entrada vs tiempo", filas)
Comun.guardar_csv("problema1", filas)
Comun.guardar_grafica("problema1", "Problema 1  -  O(n^2 log n)", filas)
