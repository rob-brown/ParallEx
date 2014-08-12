defmodule Splitter do
	use Behaviour

	@type t :: Splitter.t
	@type splitters :: [ t ]

	defcallback split(t) :: splitters
	defcallback reduce(Enum.t, Enum.acc, Enum.reducer)
	defcallback member?(Enum.t, term)
	defcallback count(Enum.t)
	defcallback new()
	defcallback into(t)

	@spec split(t) :: splitters
	def split(splitter), do: splitter.__struct__.split(splitter)

	def reduce(splitter, acc, fun), do: splitter.__struct__.reduce(splitter, acc, fun)

	def member?(splitter, value), do: splitter.__struct__.member?(splitter, value)

	def count(splitter), do: splitter.__struct__.count(splitter)

	def new(splitter), do: splitter.__struct__.new()

	def into(splitter), do: splitter.__struct__.into(splitter)

	@doc false
	defmacro __using__(_) do
		quote do
			defimpl Enumerable, for: __MODULE__ do
				def reduce(_,        { :halt, acc }, _fun),   do: { :halted, acc }
				def reduce(splitter, { :suspend, acc }, fun), do: { :suspended, acc, &reduce(splitter, &1, fun) }
				def reduce(splitter, { :cont, acc }, fun),    do: Splitter.reduce(splitter, { :cont, acc }, fun)

				def member?(collection, value),   do: Splitter.member?(collection, value)
				def count(collection),            do: Splitter.count(collection)
			end

			defimpl Collectable, for: __MODULE__ do
				def empty(collection), do: Splitter.new(collection)
				def into(collection), do: Splitter.into(collection)
			end
		end
	end
end
