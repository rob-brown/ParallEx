defmodule List.Parallel.Combiner do
  use Combiner

  defstruct lists: []

  def new(), do: %List.Parallel.Combiner{}

  def new(list) when is_list(list) do
    %List.Parallel.Combiner{lists: [ list ]}
  end

  def combine(combiner1, combiner2) do
    new_lists = combiner1.lists ++ combiner2.lists
    %List.Parallel.Combiner{lists: new_lists}
  end

  def result(combiner) do
    combiner.lists
      |> Enum.reduce([], &(&2 ++ &1))
      |> List.Parallel.new()
  end
end
