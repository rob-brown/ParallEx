defmodule ParallelList do

	defstruct list: [], count: 0

	# defrecordp :plist, ParallelList,
	#   list: [] :: list,
	#   count: 0 :: integer

	def new(list \\ []) when is_list(list) do
		%ParallelList{list: list, count: Enum.count(list)}
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
			# |> IO.inspect
			|> collect_responses(acc, combiner)
			# |> IO.inspect
			# |> process_responses(acc, combiner)
	end

	defp spawn_jobs(splitters, acc, fun) do
		me = self
		Enum.map(splitters, fn splitter ->
		                      # IO.puts "Splitter #{inspect splitter}"
		                      spawn(fn ->
		                              result = Enumerable.reduce(splitter, acc, fun) #|> elem(1) |> Enum.reverse()
		                              # IO.puts "Result: #{inspect result}"
		                              send me, { self, result }
		                            end)
						            end)
	end

	defp collect_responses(pids, acc, fun) do
		Enum.reduce(pids, acc, fn pid, local_acc ->
			            	 receive do
			            		 { ^pid, { :cont, result } } -> fun.(result, local_acc)
			            		 { ^pid, { :halt, result } } -> fun.(result, local_acc) # TODO: Stop other processes.
			            		 { ^pid, { :done, result } } -> fun.(result, local_acc) # TODO: Stop other processes.
			            	 end
			             end)
	end

	# defp collect_response(response, acc) do
	#
	# 	_collect_response(response, acc, Enumerable.impl_for(response))
	# 	# Otherwise, wrap it into a list, then use into.
	# 	# ???: How do I know if I have an Enumerable?
	# 	# I could create a protocol and implement it for all known Enumerables.
	# 	# Users of this library would need to implement the protocol for their classes too.
	# end
	#
	# defp _collect_response(response, acc, nil) do
	# 	Enum.into([response], acc)
	# end
	# defp _collect_response(response, acc, _module) do
	# 	Enum.into(response, acc)
	# end

	# defp process_responses(responses, acc, fun) do
	# 	Enumerable.reduce(responses, acc, fun)
	# end

	def count(collection) do
	  { :ok, collection.count }
	end

	def member?(collection, value) do

	  # TODO: Create a messenger that will spawn several processes. The processes will calculate membership. Once one process finds membership, kill the other processes.
	  # ???: Could I use a mapreduce? I could have the mapper return { index, processed-sublist }. It will also run the reducer on the sublist. From there the reducer will handle the tuples.

		# !!!: This is just for now.
		{ :ok, Enum.member?(collection.list, value) }
	end

	defp split(collection, _n) do
	  splitter = ParallelList.Splitter.new(collection.list) # I should switch this to use the factory methods
	  _split [ splitter ], collection.count
	end

	@min_partition 1000

	# Splits the splitters until the partition size is under some threshold.
	# This could also split into a multiple of the number of the schedulers.
	# Only profiling will tell what works best.
	defp _split(splitters, size) when size <= @min_partition, do: splitters
	defp _split(splitters, size) do
		# IO.puts "Split"
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

# defimpl Enumerable, for: ParallelList do
# 	def reduce(_,        { :halt, acc }, _fun),   do: { :halted, acc }
# 	def reduce(splitter, { :suspend, acc }, fun), do: { :suspended, acc, &reduce(splitter, &1, fun) }
# 	def reduce(splitter, { :cont, acc }, fun),    do: ParallelList.reduce(splitter, { :cont, acc }, fun)
#
#   def member?(collection, value),   do: ParallelList.member?(collection, value)
#   def count(collection),            do: ParallelList.count(collection)
# end

defimpl ParallelEnumerable, for: ParallelList do
	def reduce(_,          { :halt, acc }, _reducer, _combiner, _n), do: { :halted, acc }
	def reduce(collection, { :suspend, acc }, reducer, combiner, n), do: { :suspended, acc, &reduce(collection, &1, reducer, combiner, n) }
	def reduce(collection, { :cont, acc }, reducer, combiner, n),    do: ParallelList.reduce(collection, { :cont, acc }, reducer, combiner, n)

	def member?(collection, value), do: ParallelList.member?(collection, value)
	def count(collection),          do: ParallelList.count(collection)
end
