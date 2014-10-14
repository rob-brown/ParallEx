defmodule ParallelListTest do
  use ExUnit.Case, async: true

  def generate_data do
    [
      [],
      Enum.to_list(1..10),
      Enum.to_list(1..100),
      Enum.to_list(1..1000),
      Enum.to_list(1..10000),
      Enum.to_list(1..100000),
      Enum.to_list(1..1000000),
    ]
  end

  setup do
    { :ok, lists: generate_data }
  end

  test "map", %{lists: lists} do
    map = fn module, x -> module.map(x, &(&1 * 2)) end
    for l <- lists do
      assert map.(Enum, l) == map.(Enum.Parallel, l)
    end
  end

  test "reduce", %{lists: lists} do
    sum = fn module, x -> module.reduce(x, 0, &(&1 + &2)) end
    for l <- lists do
      assert sum.(Enum, l) == sum.(Enum.Parallel, l)
    end
  end

  test "member?", %{lists: lists} do
    test = fn l ->
             count = Enum.count l
             assert Enum.Parallel.member?(l, Enum.at(l, 0))
             assert Enum.Parallel.member?(l, Enum.at(l, 1))
             assert Enum.Parallel.member?(l, Enum.at(l, count - 2))
             assert Enum.Parallel.member?(l, Enum.at(l, count - 1))
           end
    for l <- lists, l != [], do: test.(l)
  end

  test "count", %{lists: lists} do
    for l <- lists do
      assert Enum.count(l) == Enum.Parallel.count(l)
    end
  end
end
