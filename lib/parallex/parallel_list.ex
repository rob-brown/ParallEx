defmodule List.Parallel do

	defstruct list: [], count: 0

	def new(list \\ []) when is_list(list) do
		%List.Parallel{list: list, count: Enum.count(list)}
	end

	def reduce(collection, acc, reducer, combiner, opts) do
		reduce_with_tasks(collection, acc, reducer, combiner, opts)
	end

	def reduce_with_spawn(collection, acc, reducer, combiner, opts) do
		collection
			|> split(opts.partition_count)
			|> spawn_jobs(acc, reducer)
			|> collect_responses(acc, combiner)
	end

	def reduce_with_tasks(collection, acc, reducer, combiner, opts) do
		{ :ok, sup } = Task.Supervisor.start_link()
		map_job = &(fn -> Enumerable.reduce(&1, acc, reducer) end)
		reduce_job = &(&1 |> Task.await(opts.timeout) |> elem(1) |> combiner.(&2))
		collection
			|> split(opts.partition_count)
			|> Enum.map(&(Task.Supervisor.async(sup, map_job.(&1))))
			|> Enum.reduce(acc, reduce_job)
	end

	def reduce_with_skel(collection, acc, reducer, combiner, opts) do
		worker_count = 2 * :erlang.system_info(:schedulers_online)
		map_job = &(Enumerable.reduce(&1, acc, reducer) |> elem(1))
		reduce_job = &(Enum.reduce(&2, &1, combiner))
		collection
			|> split(opts.partition_count)
			|> (&([&1])).()
			|> ExSkel.sync([{ :ord, [{ :map, [{ :seq, map_job }], worker_count }] }])
			|> ExSkel.sync([{ :reduce, reduce_job, &(IO.inspect &1) }])
			|> List.last
			|> (&({ :done, &1 })).()
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

	defp split(collection, n) do
	  splitter = List.Parallel.Splitter.new(collection.list) # I should switch this to use the factory methods
	  _split [ splitter ], 0, 1, n
	end

	defp _split(splitters, prev_count, count, _n) when prev_count == count, do: splitters
	defp _split(splitters, _prev_count, count, n) when count >= n, do: splitters
	defp _split(splitters, _prev_count, count, n) do
	  new_splitters = splitters
	                    |> Enum.reduce([], &split_reducer/2)
	                    |> Enum.reverse()
		new_count = Enum.count(new_splitters)
		_split new_splitters, count, new_count, n
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
	def reduce(_,          { :halt, acc }, _reducer, _combiner, _opts), do: { :halted, acc }
	def reduce(collection, { :suspend, acc }, reducer, combiner, opts), do: { :suspended, acc, &reduce(collection, &1, reducer, combiner, opts) }
	def reduce(collection, { :cont, acc }, reducer, combiner, opts),    do: List.Parallel.reduce(collection, { :cont, acc }, reducer, combiner, opts)

	def member?(collection, value), do: { :ok, Enum.member?(collection.list, value) }  # { :error, __MODULE__ }
	def count(collection),          do: { :ok, collection.count }
end
