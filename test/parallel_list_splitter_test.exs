defmodule ParallelListSplitterTest do
  use ExUnit.Case, async: true

  test "split" do
    assert Splittable.split([]) == [[]]
    assert Splittable.split([1]) == [[1]]
    assert Splittable.split(Enum.to_list(1..10)) == [Enum.to_list(1..5), Enum.to_list(6..10)]
  end
end
