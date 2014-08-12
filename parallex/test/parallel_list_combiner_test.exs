defmodule ParallelListCombinerTest do
  use ExUnit.Case

  test "new" do
    assert %ParallelList.Combiner{lists: []} == ParallelList.Combiner.new()
    assert %ParallelList.Combiner{lists: [[]]} == ParallelList.Combiner.new([])
    assert %ParallelList.Combiner{lists: [[ 1, 2, 3 ]]} == ParallelList.Combiner.new([1, 2, 3])
  end

  test "result" do
    c0 = ParallelList.Combiner.new()
    c1 = ParallelList.Combiner.new([])
    c2 = ParallelList.Combiner.new([ 1, 2, 3 ])

    assert Combiner.result(c0).list == []
    assert Combiner.result(c1).list == []
    assert Combiner.result(c2).list == [ 1, 2, 3 ]
  end

  test "combine" do
    c0 = ParallelList.Combiner.new()
    c1 = ParallelList.Combiner.new([])
    c2 = ParallelList.Combiner.new([ 1, 2, 3 ])
    c3 = ParallelList.Combiner.new([ 4, 5, 6 ])

    # Tests that combining two combiners results in a new combiner.
    combined1 = Combiner.combine c2, c3
    assert %ParallelList.Combiner{lists: [[ 1, 2, 3 ], [ 4, 5, 6 ]]} == combined1
    assert [ 1, 2, 3, 4, 5, 6 ] == Combiner.result(combined1).list

    # Tests combining order.
    combined1 = Combiner.combine c3, c2
    assert %ParallelList.Combiner{lists: [[ 4, 5, 6 ], [ 1, 2, 3 ]]} == combined1
    assert [ 4, 5, 6, 1, 2, 3 ] == Combiner.result(combined1).list

    # Tests that combining a combiner with itself does nothing.
    assert c2 == Combiner.combine c2, c2

    # Tests that combining with an empty combiner works.
    combined2 = Combiner.combine c0, c2
    assert %ParallelList.Combiner{lists: [[ 1, 2, 3 ]]} == combined2
    assert Combiner.result(c2) == Combiner.result(combined2)

    combined3 = Combiner.combine c1, c2
    assert %ParallelList.Combiner{lists: [[], [ 1, 2, 3 ]]} == combined3
    assert Combiner.result(c2) == Combiner.result(combined3)
  end
end
