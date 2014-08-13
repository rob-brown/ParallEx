defmodule List.Parallel do

	defstruct list: [], count: 0

	def new(list \\ []) when is_list(list) do
		%List.Parallel{list: list, count: Enum.count(list)}
	end

	def reduce(collection, acc, reducer, combiner, n) do

	  # ???: How do I need to handle the accumulator?

		# ???: Should I change this to use tasks? What if I have problems with time outs?

	  # For now, this runs each splitter on its own process.
	  # This is not scalable and should be used with a process pool or similar technique.
	  # It should also watch out for processes that die.
	  # To properly do this, I should move this code into a different module.
	  collection
	    |> split(n)
			|> spawn_jobs(acc, reducer)
			|> collect_responses(acc, combiner)
	end

	defp spawn_jobs(splitters, acc, fun) do
		me = self
		Enum.map(splitters, fn splitter ->
		                      spawn(fn ->
		                              send me, { self, Enumerable.reduce(splitter, acc, fun) }
		                            end)
						            end)
	end

	defp collect_responses(pids, acc, fun) do
		Enum.reduce(pids, acc, fn pid, local_acc ->
			            	 receive do
			            		 { ^pid, { _, result } } -> fun.(result, local_acc)
			            	 end
			             end)
	end

	defp split(collection, _n) do
	  splitter = List.Parallel.Splitter.new(collection.list) # I should switch this to use the factory methods
	  _split [ splitter ], collection.count
	end

	@min_partition 1000

	# Splits the splitters until the partition size is under some threshold.
	# This could also split into a multiple of the number of the schedulers.
	# Only profiling will tell what works best.
	defp _split(splitters, size) when size <= @min_partition, do: splitters
	defp _split(splitters, size) do
	  splitters
	    |> Enum.reduce([], &split_reducer/2)
	    |> Enum.reverse()
	    |> _split(div(size, 2))
	end

	defp split_reducer(splitter, acc) do
	  case Splitter.split(splitter) do
	    [ splitter1, splitter2 ] ->
	      [ splitter2, splitter1 | acc ]
	    [ splitter1 ] ->
	      [ splitter1 | acc ]
	    _ ->
	      raise ArgumentError, message: "Splitter didn't split as expected: #{inspect splitter}"
	  end
	end
end

# defimpl Enumerable, for: List.Parallel do
# 	def reduce(_,        { :halt, acc }, _fun),   do: { :halted, acc }
# 	def reduce(splitter, { :suspend, acc }, fun), do: { :suspended, acc, &reduce(splitter, &1, fun) }
# 	def reduce(splitter, { :cont, acc }, fun),    do: List.Parallel.reduce(splitter, { :cont, acc }, fun)
#
#   def member?(collection, value),   do: List.Parallel.member?(collection, value)
#   def count(collection),            do: List.Parallel.count(collection)
# end

defimpl Enumerable.Parallel, for: List.Parallel do
	def reduce(_,          { :halt, acc }, _reducer, _combiner, _n), do: { :halted, acc }
	def reduce(collection, { :suspend, acc }, reducer, combiner, n), do: { :suspended, acc, &reduce(collection, &1, reducer, combiner, n) }
	def reduce(collection, { :cont, acc }, reducer, combiner, n),    do: List.Parallel.reduce(collection, { :cont, acc }, reducer, combiner, n)

	def member?(collection, value), do: { :ok, Enum.member?(collection.list, value) }  # { :error, __MODULE__ }
	def count(collection),          do: { :ok, collection.count }
end
