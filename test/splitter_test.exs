defmodule SplitterTest do
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
    assert Enum.count(list1) == Enum.count(list2) + 1 or Enum.count(list2) == Enum.count(list1) + 1
  end

  test "split empty set" do
    assert Splittable.split(HashSet.new) == [HashSet.new]
  end

  test "split single-item set" do
    assert Splittable.split(Enum.into([1], HashSet.new)) == [Enum.into([1], HashSet.new)]
  end

  test "split even-numbered, many-item set" do
    [set1, set2] = Splittable.split(Enum.into(1..10_000, HashSet.new))
    assert Enum.count(set1) == Enum.count(set2)
  end

  test "split odd-numbered, many-item set" do
    [set1, set2] = Splittable.split(Enum.into(1..10_001, HashSet.new))
    assert Enum.count(set1) == Enum.count(set2) + 1 or Enum.count(set2) == Enum.count(set1) + 1
  end

  test "split empty dict" do
    assert Splittable.split(HashDict.new) == [HashDict.new]
  end

  test "split single-item dict" do
    assert Splittable.split(Enum.into([{1, 1}], HashDict.new)) == [Enum.into([{1, 1}], HashDict.new)]
  end

  test "split even-numbered, many-item dict" do
    dict = for x <- 1..10, into: HashDict.new, do: {x, :value}
    [dict1, dict2] = Splittable.split dict
    assert Enum.count(dict1) == Enum.count(dict2)
  end

  test "split odd-numbered, many-item dict" do
      dict = for x <- 1..10_0001, into: HashDict.new, do: {x, :value}
      [dict1, dict2] = Splittable.split dict
    assert Enum.count(dict1) == Enum.count(dict2) + 1 or Enum.count(dict2) == Enum.count(dict1) + 1
  end
end
