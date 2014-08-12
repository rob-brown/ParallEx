defmodule Combiner do
  use Behaviour

  @type t :: Combiner.t
  @type collection :: Enum.t

  defcallback combine(t, t) :: t
  defcallback result(t) :: collection
  defcallback new() :: t
  # defcallback add(t, term) :: t

  def new(combiner), do: combiner.__struct__.new()

  def combine(c, c), do: c
  def combine(combiner1, combiner2), do: combiner1.__struct__.combine(combiner1, combiner2)
  # def combine(combiner1, combiner2), do: Enum.into(combiner2, combiner1)

  # Can the combine function just call into/1?
  # It looks like I have to conform to the enumerable protocol.

  def result(combiner), do: combiner.__struct__.result(combiner)

  # def add(combiner, term), do: combiner.__struct__.add(combiner, term)

  @doc false
  defmacro __using__(_) do
    quote do
      # defimpl Collectable, for: __MODULE__ do
      #   def empty(collectable), do: Combiner.new(collectable)
      #   def into(original), do: { original, fn
      #                                         collectable, { :cont, x } -> Combiner.add(collectable, x)
      #                                         collectable, :done -> collectable
      #                                         _, :halt -> :ok
      #                                       end }
      # end
    end
  end
end
