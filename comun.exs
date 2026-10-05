# ============================================================
# Funciones compartidas por los tres problemas del laboratorio:
# medicion de tiempo, tablas de resultados y graficas.
# ============================================================

defmodule Comun do
  # ------------------------------------------------------------
  # Tamanos de entrada que pide el laboratorio
  # ------------------------------------------------------------
  def tamanos, do: [1, 10, 100, 1_000, 10_000, 100_000, 1_000_000]

  # ------------------------------------------------------------
  # Carpeta donde se guardan las tablas y las graficas
  # ------------------------------------------------------------
  def carpeta, do: Path.join(__DIR__, "resultados")

  # ------------------------------------------------------------
  # Dice si se pidio el modo rapido al correr el programa, que
  # sirve para hacer una demostracion sin esperar tanto
  # ------------------------------------------------------------
  def modo_rapido?, do: "rapido" in System.argv()

  # ------------------------------------------------------------
  # Deja fuera los tamanos grandes cuando se pide el modo rapido
  # ------------------------------------------------------------
  def filtrar(lista) do
    if modo_rapido?(), do: Enum.filter(lista, &(&1 <= 10_000)), else: lista
  end

  # ------------------------------------------------------------
  # Cuantas veces repetir cada medicion. Las entradas chicas se
  # repiten muchas veces porque si no el tiempo sale en cero.
  # ------------------------------------------------------------
  def repeticiones(n) when n <= 100, do: 10_000
  def repeticiones(n) when n <= 1_000, do: 100
  def repeticiones(n) when n <= 10_000, do: 3
  def repeticiones(_n), do: 1

  # ------------------------------------------------------------
  # Ejecuta una funcion varias veces y devuelve el tiempo promedio
  # de una sola ejecucion, en segundos
  # ------------------------------------------------------------
  def medir_promedio(funcion, veces) do
    {microsegundos, _} = :timer.tc(fn -> Enum.each(1..veces, fn _ -> funcion.() end) end)
    microsegundos / 1_000_000 / veces
  end

  # ------------------------------------------------------------
  # Cuenta cuantas potencias de 2 (1, 2, 4, 8, ...) caben hasta n
  # ------------------------------------------------------------
  def potencias_de_dos(n), do: contar_potencias(1, n, 0)

  defp contar_potencias(k, n, cuenta) when k > n, do: cuenta
  defp contar_potencias(k, n, cuenta), do: contar_potencias(k * 2, n, cuenta + 1)

  # ------------------------------------------------------------
  # Corre el programa para cada tamano de la lista "medidos" y arma
  # la tabla. Los tamanos de la lista "estimados" no se ejecutan:
  # su tiempo se proyecta con el costo por iteracion del tamano
  # medido mas grande.
  # ------------------------------------------------------------
  def perfilar(ejecutar, contar, medidos, estimados \\ []) do
    filas =
      Enum.map(medidos, fn n ->
        veces = repeticiones(n)
        tiempo = medir_promedio(fn -> ejecutar.(n) end, veces)
        IO.puts("  n = #{con_comas(n)}  ->  #{formato(tiempo)} s  (#{veces} repeticion/es)")
        {n, contar.(n), tiempo, :medido}
      end)

    costo = if estimados == [], do: 0.0, else: costo_por_iteracion(filas)

    proyectadas =
      Enum.map(estimados, fn n ->
        iteraciones = contar.(n)
        tiempo = iteraciones * costo
        IO.puts("  n = #{con_comas(n)}  ->  #{formato(tiempo)} s  (estimado)")
        {n, iteraciones, tiempo, :estimado}
      end)

    filas ++ proyectadas
  end

  # ------------------------------------------------------------
  # Costo promedio de una iteracion, tomado del tamano medido
  # mas grande de la tabla
  # ------------------------------------------------------------
  defp costo_por_iteracion(filas) do
    {_n, iteraciones, tiempo, _tipo} =
      filas
      |> Enum.filter(fn {_n, it, _t, _tipo} -> it > 0 end)
      |> List.last()

    tiempo / iteraciones
  end

  # ------------------------------------------------------------
  # Escribe una cantidad de segundos de forma legible
  # ------------------------------------------------------------
  def formato(valor) do
    valor = valor * 1.0

    if valor >= 1.0 do
      :erlang.float_to_binary(valor, decimals: 4)
    else
      :erlang.float_to_binary(valor, decimals: 9)
    end
  end

  # ------------------------------------------------------------
  # Escribe un entero con separadores de miles (1000000 -> 1,000,000)
  # ------------------------------------------------------------
  def con_comas(numero) do
    numero
    |> Integer.to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
    |> String.reverse()
  end

  # ------------------------------------------------------------
  # Imprime la tabla de resultados en la consola
  # ------------------------------------------------------------
  def imprimir_tabla(titulo, filas) do
    raya = String.duplicate("-", 66)

    IO.puts("")
    IO.puts(titulo)
    IO.puts(raya)

    IO.puts(
      String.pad_trailing("n", 14) <>
        String.pad_trailing("iteraciones", 22) <>
        String.pad_trailing("tiempo (s)", 20) <> "tipo"
    )

    IO.puts(raya)

    Enum.each(filas, fn {n, iteraciones, tiempo, tipo} ->
      IO.puts(
        String.pad_trailing(con_comas(n), 14) <>
          String.pad_trailing(con_comas(iteraciones), 22) <>
          String.pad_trailing(formato(tiempo), 20) <> Atom.to_string(tipo)
      )
    end)

    IO.puts(raya)
  end

  # ------------------------------------------------------------
  # Guarda la tabla de resultados en un archivo CSV
  # ------------------------------------------------------------
  def guardar_csv(nombre, filas) do
    File.mkdir_p!(carpeta())
    ruta = Path.join(carpeta(), nombre <> ".csv")

    lineas =
      Enum.map(filas, fn {n, iteraciones, tiempo, tipo} ->
        "#{n},#{iteraciones},#{formato(tiempo)},#{tipo}"
      end)

    File.write!(ruta, Enum.join(["n,iteraciones,tiempo_segundos,tipo" | lineas], "\n") <> "\n")
    IO.puts("Tabla guardada en    resultados/#{nombre}.csv")
  end

  # ------------------------------------------------------------
  # Guarda la grafica de tamano de entrada vs tiempo en formato SVG
  # ------------------------------------------------------------
  def guardar_grafica(nombre, titulo, filas) do
    File.mkdir_p!(carpeta())
    ruta = Path.join(carpeta(), nombre <> ".svg")
    File.write!(ruta, dibujar(titulo, filas))
    IO.puts("Grafica guardada en  resultados/#{nombre}.svg")
  end

  # ------------------------------------------------------------
  # Arma el SVG completo. Los dos ejes van en escala logaritmica
  # porque los tiempos van desde microsegundos hasta minutos.
  # ------------------------------------------------------------
  defp dibujar(titulo, filas) do
    puntos =
      Enum.map(filas, fn {n, _it, tiempo, tipo} ->
        {:math.log10(max(n, 1)), :math.log10(max(tiempo, 1.0e-9)), tipo}
      end)

    alturas = Enum.map(puntos, fn {_x, y, _tipo} -> y end)
    y_min = Float.floor(Enum.min(alturas))
    y_max = Float.ceil(Enum.max(alturas))
    y_max = if y_max <= y_min, do: y_min + 1.0, else: y_max

    medidos = Enum.filter(puntos, fn {_x, _y, tipo} -> tipo == :medido end)
    estimados = Enum.filter(puntos, fn {_x, _y, tipo} -> tipo == :estimado end)
    tramo_estimado = if estimados == [], do: [], else: [List.last(medidos) | estimados]

    Enum.join([
      cabecera(titulo),
      rejilla_vertical(),
      rejilla_horizontal(y_min, y_max),
      ejes(),
      linea_punteada(tramo_estimado, y_min, y_max),
      linea_solida(medidos, y_min, y_max),
      marcadores(medidos, y_min, y_max),
      marcadores(estimados, y_min, y_max),
      leyenda(estimados),
      "</svg>\n"
    ], "\n")
  end

  # ------------------------------------------------------------
  # Fondo blanco y titulo de la grafica
  # ------------------------------------------------------------
  defp cabecera(titulo) do
    ~s|<svg xmlns="http://www.w3.org/2000/svg" width="820" height="540" viewBox="0 0 820 540" font-family="Arial, Helvetica, sans-serif">\n| <>
      ~s|  <rect width="820" height="540" fill="#ffffff"/>\n| <>
      ~s|  <text x="445" y="36" text-anchor="middle" font-size="19" font-weight="bold" fill="#111827">#{titulo}</text>\n| <>
      ~s|  <text x="445" y="57" text-anchor="middle" font-size="12" fill="#6b7280">los dos ejes estan en escala logaritmica</text>|
  end

  # ------------------------------------------------------------
  # Lineas de los dos ejes y sus nombres
  # ------------------------------------------------------------
  defp ejes do
    ~s|  <line x1="100" y1="440" x2="790" y2="440" stroke="#374151" stroke-width="1.5"/>\n| <>
      ~s|  <line x1="100" y1="80" x2="100" y2="440" stroke="#374151" stroke-width="1.5"/>\n| <>
      ~s|  <text x="445" y="487" text-anchor="middle" font-size="13" fill="#374151">tamano de la entrada (n)</text>\n| <>
      ~s|  <text x="26" y="260" text-anchor="middle" font-size="13" fill="#374151" transform="rotate(-90 26 260)">tiempo de ejecucion (segundos)</text>|
  end

  # ------------------------------------------------------------
  # Pasa un valor del eje X (log10 de n) a pixeles
  # ------------------------------------------------------------
  defp px(x), do: 100 + x / 6 * 690

  # ------------------------------------------------------------
  # Pasa un valor del eje Y (log10 del tiempo) a pixeles
  # ------------------------------------------------------------
  defp py(y, y_min, y_max), do: 440 - (y - y_min) / (y_max - y_min) * 360

  # ------------------------------------------------------------
  # Traza la curva que une los puntos realmente medidos
  # ------------------------------------------------------------
  defp linea_solida(puntos, y_min, y_max) do
    ~s|  <polyline fill="none" stroke="#2563eb" stroke-width="2.5" points="#{coordenadas(puntos, y_min, y_max)}"/>|
  end

  # ------------------------------------------------------------
  # Traza el tramo punteado que llega al punto estimado
  # ------------------------------------------------------------
  defp linea_punteada([], _y_min, _y_max), do: ""

  defp linea_punteada(puntos, y_min, y_max) do
    ~s|  <polyline fill="none" stroke="#f97316" stroke-width="2.5" stroke-dasharray="7 5" points="#{coordenadas(puntos, y_min, y_max)}"/>|
  end

  # ------------------------------------------------------------
  # Convierte una lista de puntos en la cadena que usa polyline
  # ------------------------------------------------------------
  defp coordenadas(puntos, y_min, y_max) do
    Enum.map_join(puntos, " ", fn {x, y, _tipo} ->
      "#{redondear(px(x))},#{redondear(py(y, y_min, y_max))}"
    end)
  end

  # ------------------------------------------------------------
  # Dibuja un circulo sobre cada punto. Los medidos van rellenos
  # y los estimados van huecos.
  # ------------------------------------------------------------
  defp marcadores(puntos, y_min, y_max) do
    Enum.map_join(puntos, "\n", fn {x, y, tipo} ->
      color = if tipo == :medido, do: "#2563eb", else: "#f97316"
      relleno = if tipo == :medido, do: color, else: "#ffffff"

      ~s|  <circle cx="#{redondear(px(x))}" cy="#{redondear(py(y, y_min, y_max))}" r="5" fill="#{relleno}" stroke="#{color}" stroke-width="2.5"/>|
    end)
  end

  # ------------------------------------------------------------
  # Lineas verticales de la rejilla, una por cada potencia de 10
  # ------------------------------------------------------------
  defp rejilla_vertical do
    Enum.map_join(0..6, "\n", fn k ->
      x = redondear(px(k * 1.0))

      ~s|  <line x1="#{x}" y1="80" x2="#{x}" y2="440" stroke="#e5e7eb" stroke-width="1"/>\n| <>
        ~s|  <text x="#{x}" y="459" text-anchor="middle" font-size="11" fill="#6b7280">#{con_comas(trunc(:math.pow(10, k)))}</text>|
    end)
  end

  # ------------------------------------------------------------
  # Lineas horizontales de la rejilla, una por cada potencia de 10
  # ------------------------------------------------------------
  defp rejilla_horizontal(y_min, y_max) do
    Enum.map_join(trunc(y_min)..trunc(y_max), "\n", fn k ->
      y = redondear(py(k * 1.0, y_min, y_max))

      ~s|  <line x1="100" y1="#{y}" x2="790" y2="#{y}" stroke="#e5e7eb" stroke-width="1"/>\n| <>
        ~s|  <text x="92" y="#{y + 4}" text-anchor="end" font-size="11" fill="#6b7280">#{etiqueta_tiempo(k)}</text>|
    end)
  end

  # ------------------------------------------------------------
  # Texto de una marca del eje Y a partir de su exponente
  # ------------------------------------------------------------
  defp etiqueta_tiempo(k) when k >= 0, do: con_comas(trunc(:math.pow(10, k)))
  defp etiqueta_tiempo(k), do: "1e#{k}"

  # ------------------------------------------------------------
  # Recuadro que explica los colores de la grafica
  # ------------------------------------------------------------
  defp leyenda(estimados) do
    medido =
      ~s|  <circle cx="600" cy="505" r="5" fill="#2563eb"/>\n| <>
        ~s|  <text x="614" y="509" font-size="12" fill="#374151">medido</text>|

    if estimados == [] do
      medido
    else
      medido <>
        ~s|\n  <circle cx="686" cy="505" r="5" fill="#ffffff" stroke="#f97316" stroke-width="2.5"/>\n| <>
        ~s|  <text x="700" y="509" font-size="12" fill="#374151">estimado</text>|
    end
  end

  # ------------------------------------------------------------
  # Deja un numero con un decimal para que el SVG no quede enorme
  # ------------------------------------------------------------
  defp redondear(valor), do: Float.round(valor * 1.0, 1)
end
