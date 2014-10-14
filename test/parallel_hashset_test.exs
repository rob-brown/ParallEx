defmodule ParallelHashSetTest do
  use ExUnit.Case, async: true

  # !!!: I could make a test for each value in the dataset.
  defp generate_data do
    [
      [],
      Enum.into(1..1, HashSet.new),
      Enum.into(1..10, HashSet.new),
      Enum.into(1..100, HashSet.new),
      Enum.into(1..1000, HashSet.new),
      Enum.into(1..10000, HashSet.new),
      Enum.into(1..100000, HashSet.new),
    ]
  end

  setup do
    { :ok, sets: generate_data }
  end

  test "map", %{sets: sets} do
    map = fn module, s -> module.map(s, &(&1 * 2)) end
    for s <- sets do
      assert map.(Enum, s) == map.(Enum.Parallel, s)
    end
  end

  test "reduce", %{sets: sets} do
    sum = fn module, s -> module.reduce(s, 0, &(&1 + &2)) end
    for s <- sets do
      assert sum.(Enum, s) == sum.(Enum.Parallel, s)
    end
  end

  test "member?", %{sets: sets} do
    test = fn s ->
             count = Enum.count s
             assert Enum.Parallel.member?(s, Enum.at(s, 0))
             assert Enum.Parallel.member?(s, Enum.at(s, 1))
             assert Enum.Parallel.member?(s, Enum.at(s, count - 2))
             assert Enum.Parallel.member?(s, Enum.at(s, count - 1))
           end
    for s <- sets, Enum.Parallel.count(s) > 4, do: test.(s)
  end

  test "count", %{sets: sets} do
    for s <- sets do
      assert Enum.count(s) == Enum.Parallel.count(s)
    end
  end
end
