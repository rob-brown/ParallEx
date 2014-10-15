defmodule ListSplitterTest do
  use ExUnit.Case, async: true

  test "split empty list" do
    assert Splittable.split([]) == [[]]
  end

  test "split single-item list" do
    assert Splittable.split([1]) == [[1]]
  end

  test "split even-numbered, many-item list" do
    assert Splittable.split(Enum.to_list(1..10)) == [Enum.to_list(1..5), Enum.to_list(6..10)]
  end

  test "split odd-numbered, many-item list" do
    [list1, list2] = Splittable.split(Enum.to_list(1..10_001))
    assert abs(Enum.count(list1) - Enum.count(list2)) == 1
  end
end

defmodule RangeSplitterTest do
  use ExUnit.Case, async: true

  test "split single-item range" do
    assert Splittable.split([1..1]) == [[1..1]]
  end

  test "split even-numbered, many-item range" do
    assert Splittable.split(1..10) == [1..5, 6..10]
  end

  test "split odd-numbered, many-item range" do
    [range1, range2] = Splittable.split(0..10_000)
    assert abs(Enum.count(range1) - Enum.count(range2)) == 1
  end

  test "split backward range" do
    assert Splittable.split(9..0) == [9..5, 4..0]
  end

  test "split negative range" do
    assert Splittable.split(-2..3) == [-2..0, 1..3]
  end
end

defmodule HashSetSplitterTest do
  use ExUnit.Case, async: true

  test "split empty set" do
    assert Splittable.split(HashSet.new) == [HashSet.new]
  end

  test "split single-item set" do
    set = Enum.into([1], HashSet.new)
    assert Splittable.split(set) == [set]
  end

  test "split even-numbered, many-item set" do
    [set1, set2] = Splittable.split(Enum.into(1..10_000, HashSet.new))
    assert Enum.count(set1) == Enum.count(set2)
  end

  test "split odd-numbered, many-item set" do
    [set1, set2] = Splittable.split(Enum.into(1..10_001, HashSet.new))
    assert abs(Enum.count(set1) - Enum.count(set2)) == 1
  end
end

defmodule HashDictSplitterTest do
  use ExUnit.Case, async: true

  test "split empty dict" do
    assert Splittable.split(HashDict.new) == [HashDict.new]
  end

  test "split single-item dict" do
    dict = Enum.into [{1, 1}], HashDict.new
    assert Splittable.split(dict) == [dict]
  end

  test "split even-numbered, many-item dict" do
    dict = for x <- 1..10_000, into: HashDict.new, do: {x, :value}
    [dict1, dict2] = Splittable.split dict
    assert Enum.count(dict1) == Enum.count(dict2)
  end

  test "split odd-numbered, many-item dict" do
      dict = for x <- 1..10_0001, into: HashDict.new, do: {x, :value}
      [dict1, dict2] = Splittable.split dict
    assert abs(Enum.count(dict1) - Enum.count(dict2)) == 1
  end
end
