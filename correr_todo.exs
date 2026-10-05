# ============================================================
# Corre los tres problemas uno tras otro y deja las tablas y las
# graficas en la carpeta resultados/
#
#   elixir correr_todo.exs           corrida completa
#   elixir correr_todo.exs rapido    solo hasta n = 10,000
# ============================================================

Code.require_file("problema1.exs", __DIR__)
Code.require_file("problema2.exs", __DIR__)
Code.require_file("problema3.exs", __DIR__)

IO.puts("")
IO.puts("Listo. Las tablas (.csv) y las graficas (.svg) quedaron en resultados/")
