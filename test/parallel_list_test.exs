defmodule ParallelListTest do
  use ExUnit.Case, async: true

  def default_test_lists do
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

  test "new from list" do
    for l <- default_test_lists do
      assert List.Parallel.new(l) == %List.Parallel{list: l, count: Enum.count l}
    end
  end

  test "map" do
    map = fn module, x -> module.map(x, &(&1 * 2)) end
    for l <- default_test_lists do
      assert map.(Enum, l) == map.(Enum.Parallel, List.Parallel.new(l))
    end
  end

  test "reduce" do
    sum = fn module, x -> module.reduce(x, 0, &(&1 + &2)) end
    for l <- default_test_lists do
      assert sum.(Enum, l) == sum.(Enum.Parallel, List.Parallel.new(l))
    end
  end

  # test "join" do
  #   letters = for n <- 0..100, do: rem(n, (?z - ?a)) + ?a
  #   plist = List.Parallel.new(letters)
  #   assert Enum.join(letters, " ") == Enum.join(plist, " ")
  # end

  test "member?" do
    test = fn l ->
             count = Enum.count l
             plist = List.Parallel.new l
             assert Enum.Parallel.member?(plist, Enum.at(l, 0))
             assert Enum.Parallel.member?(plist, Enum.at(l, 1))
             assert Enum.Parallel.member?(plist, Enum.at(l, count - 2))
             assert Enum.Parallel.member?(plist, Enum.at(l, count - 1))
           end
    for l <- default_test_lists, l != [], do: test.(l)
  end

  test "count" do
    for l <- default_test_lists do
      assert Enum.count(l) == Enum.Parallel.count(List.Parallel.new l)
    end
  end
end
