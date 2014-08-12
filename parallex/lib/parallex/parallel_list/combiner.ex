defmodule ParallelList.Combiner do
  use Combiner

  defstruct lists: []

  # defrecordp :combiner, ParallelList.Combiner,
  #   lists: [] :: list

  def new(), do: %ParallelList.Combiner{}

  def new(list) when is_list(list) do
    %ParallelList.Combiner{lists: [ list ]}
  end

  def combine(combiner1, combiner2) do
    new_lists = combiner1.lists ++ combiner2.lists
    %ParallelList.Combiner{lists: new_lists}
  end

  def result(combiner) do
    combiner.lists
      |> Enum.reduce([], &(&2 ++ &1))
      |> ParallelList.new()
  end
end
