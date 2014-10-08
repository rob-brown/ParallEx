defimpl Splittable, for: List do

  def split([]), do: [[]]
  def split([x]), do: [[x]]
  def split(list) do
    len = length list
    mid = div(len, 2)
    lo_range = 0..(mid - 1)
    hi_range = mid..(len - 1)
    [
      Enum.slice(list, lo_range),
      Enum.slice(list, hi_range),
    ]
  end
end
