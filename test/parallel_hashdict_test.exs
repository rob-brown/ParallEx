defmodule ParallelHashDictTest do
  use ExUnit.Case, async: true

  defp integer_to_atom(x) do
    x |> Integer.to_string |> String.to_atom
  end

  defp generate_data do
    ranges = [
      [],
      1..1,
      1..10,
      1..100,
      1..1000,
      1..10000,
      1..100000,
    ]
    for r <- ranges do
      for x <- r, into: HashDict.new, do: { integer_to_atom(x), x }
    end
  end

  setup do
    { :ok, dicts: generate_data }
  end

  test "map", %{dicts: dicts} do
    map = fn module, d -> module.map(d, fn {x, y} -> {x, y * 2} end) end
    for d <- dicts do
      assert map.(Enum, d) == map.(Enum.Parallel, d)
    end
  end

  test "reduce", %{dicts: dicts} do
    sum = fn module, d -> module.reduce(d, {:"0", 0}, fn {x, y}, {_, acc} -> {x, y + acc} end) end
    for d <- dicts do
      assert sum.(Enum, d) == sum.(Enum.Parallel, d)
    end
  end

  test "member?", %{dicts: dicts} do
    test = fn d ->
             count = Enum.count d
             assert Enum.Parallel.member?(d, Enum.at(d, 0))
             assert Enum.Parallel.member?(d, Enum.at(d, 1))
             assert Enum.Parallel.member?(d, Enum.at(d, count - 2))
             assert Enum.Parallel.member?(d, Enum.at(d, count - 1))
           end
    for d <- dicts, Enum.Parallel.count(d) > 4, do: test.(d)
  end

  test "count", %{dicts: dicts} do
    for d <- dicts do
      assert Enum.count(d) == Enum.Parallel.count(d)
    end
  end
end
