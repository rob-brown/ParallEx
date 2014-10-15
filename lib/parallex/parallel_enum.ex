defmodule Enum.Parallel.Opts do

  # ???: Should I expose the reducing function in the options?
  # ???: Should I have an ordered option since sets have no inherent order?

  defstruct partition_count: 512,
            timeout: :infinity

  @type t :: %__MODULE__{
    partition_count: pos_integer,
    timeout: pos_integer | :infinity
  }
end

defmodule Enum.Parallel.Reducer do

  def reduce(collection, acc, reducer, combiner \\ nil, opts \\ %Enum.Parallel.Opts{})

  def reduce(collection, acc, reducer, nil, opts) do
    reduce(collection, acc, reducer, reducer, opts)
  end

  def reduce(collection, acc, reducer, combiner, opts) when is_list(opts) do
    struct_opts = struct(Enum.Parallel.Opts, opts)
    reduce(collection, acc, reducer, combiner, struct_opts)
  end

  def reduce(collection, acc, reducer, combiner, opts) do
    { :ok, sup } = Task.Supervisor.start_link()
    map_job = &(fn -> Enumerable.reduce(&1, acc, reducer) end)
    reduce_job = &(&1 |> Task.await(opts.timeout) |> elem(1) |> combiner.(&2))
    collection
      |> Splitter.split(opts)
      |> Enum.map(&(Task.Supervisor.async(sup, map_job.(&1))))
      |> Enum.reduce(acc, reduce_job)
  end
end

defmodule Enum.Parallel do

  alias Enum.Parallel.Reducer

  # Require Stream.Reducers and its callbacks
  require Stream.Reducers, as: R

  defmacrop cont(_, entry, acc) do
    quote do: {:cont, [unquote(entry)|unquote(acc)]}
  end

  defmacrop acc(h, n, _) do
    quote do: {unquote(h), unquote(n)}
  end

  defmacrop cont_with_acc(f, entry, h, n, _) do
    quote do
      {:cont, {[unquote(entry)|unquote(h)], unquote(n)}}
    end
  end

  def reduce(collection, acc, fun, combiner \\ nil, opts \\ [])

  def reduce(collection, acc, reducer, nil, opts) do
    reduce collection, acc, reducer, reducer, opts
  end

  def reduce(collection, acc, reducer, combiner, opts) do
    Reducer.reduce(collection,
                  {:cont, acc},
                  fn x, acc -> {:cont, reducer.(x, acc)} end,
                  fn x, {_, acc} -> {:cont, combiner.(x, acc)} end,
                  opts) |> elem(1)
  end

  def member?(collection, value) do
    Reducer.reduce(collection, {:cont, false}, fn
                    v, _ when v === value -> {:halt, true}
                    _, _                  -> {:cont, false}
                  end,
                  fn x, {_, acc} -> {:cont, x or acc} end) |> elem(1)
  end

  def count(collection, opts \\ []) do
    reducer = fn _, acc -> acc + 1 end
    combiner = fn x, acc -> x + acc end
    reduce(collection, 0, reducer, combiner, opts)
  end

  def map(collection, fun, opts \\ []) do
    combiner = fn x, {_, acc} -> {:cont, x ++ acc} end
    Reducer.reduce(collection, {:cont, []}, R.map(fun), combiner, opts)
      |> elem(1)
      |> :lists.reverse
  end

  def each(collection, fun, opts \\ []) do
    reducer = fn x, _ -> fun.(x); nil end
    combiner = fn _, _ -> nil end
    reduce(collection, nil, reducer, combiner, opts)
    :ok
  end
end
