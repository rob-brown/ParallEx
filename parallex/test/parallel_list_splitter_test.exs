defmodule ParallelListSplitterTest do
  use ExUnit.Case

  test "new" do
    s0 = List.Parallel.Splitter.new []
    s1 = List.Parallel.Splitter.new [1]
    s2 = List.Parallel.Splitter.new Enum.to_list(1..3)

    assert s0 == %List.Parallel.Splitter{list: [], range: 0..0}
    assert s1 == %List.Parallel.Splitter{list: [1], range: 0..0}
    assert s2 == %List.Parallel.Splitter{list: [ 1, 2, 3 ], range: 0..2}
  end

  test "split" do
    s0 = List.Parallel.Splitter.new []
    s1 = List.Parallel.Splitter.new [1]
    s2 = List.Parallel.Splitter.new Enum.to_list(1..10)

    # Tests splitting splitters that can't split any more.
    assert [s0] == Splitter.split s0
    assert [s1] == Splitter.split s1

    # Tests splitting a regular splitter.
    [ splitter1, splitter2 ] = Splitter.split s2
    assert splitter1 == %List.Parallel.Splitter{list: [ 1, 2, 3, 4, 5 ], range: 0..4}
    assert splitter2 == %List.Parallel.Splitter{list: [ 6, 7, 8, 9, 10 ], range: 5..9}

    # Tests splitting split splitters.
    [ splitter3, splitter4 ] = Splitter.split splitter1
    [ splitter5, splitter6 ] = Splitter.split splitter2
    assert splitter3 == %List.Parallel.Splitter{list: [ 1, 2, 3 ], range: 0..2}
    assert splitter4 == %List.Parallel.Splitter{list: [ 4, 5 ], range: 3..4}
    assert splitter5 == %List.Parallel.Splitter{list: [ 6, 7, 8 ], range: 5..7}
    assert splitter6 == %List.Parallel.Splitter{list: [ 9, 10 ], range: 8..9}
  end

  test "reduce" do
    sum = fn list -> Enum.reduce(list, 0, &(&1 + &2)) end
    compare_results Enum.to_list(1..1), sum
    compare_results Enum.to_list(1..10), sum
    compare_results Enum.to_list(1..10_000), sum
  end

  test "count" do
    compare_results Enum.to_list(1..1), &(Enum.count &1)
    compare_results Enum.to_list(1..10), &(Enum.count &1)
    compare_results Enum.to_list(1..10_000), &(Enum.count &1)
  end

  test "member?" do
    compare_results Enum.to_list(1..1), &(Enum.member? &1, 5)
    compare_results Enum.to_list(1..10), &(Enum.member? &1, 5)
    compare_results Enum.to_list(1..10_000), &(Enum.member? &1, 7_777)
  end

  test "empty" do
    assert List.Parallel.Splitter.new == Collectable.empty(List.Parallel.Splitter.new)
    assert List.Parallel.Splitter.new == Collectable.empty(List.Parallel.Splitter.new [])
    assert List.Parallel.Splitter.new == Collectable.empty(List.Parallel.Splitter.new [1, 2, 3])
  end

  test "into" do
    assert List.Parallel.Splitter.new([ 1, 2, 3 ]) == Enum.into([ 1, 2, 3 ], List.Parallel.Splitter.new())
    assert List.Parallel.Splitter.new([ 1, 2, 3 ]) == Enum.into([], List.Parallel.Splitter.new([ 1, 2, 3 ]))
    assert List.Parallel.Splitter.new([ 1, 2, 3, 4, 5, 6 ]) == Enum.into([ 4, 5, 6 ], List.Parallel.Splitter.new([ 1, 2, 3 ]))
  end

  defp compare_results(list, fun) do
    compare_results(list, List.Parallel.Splitter.new(list), fun)
  end
  defp compare_results(list, splitter, fun) do
    assert fun.(list) == fun.(splitter)
  end
end
