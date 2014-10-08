defmodule Enum.Parallel.Opts do

  # ???: Should I expose the reducing function in the options?

  defstruct partition_count: 512,
            timeout: :infinity

  @type t :: %__MODULE__{
    partition_count: pos_integer,
    timeout: pos_integer | :infinity
  }
end

defmodule Enum.Parallel.Reducer do
  def reduce(collection, acc, reducer, combiner, opts \\ %Enum.Parallel.Opts{}) do
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

  def reduce(collection, acc, fun, _combiner, _opts) when is_list(collection) do
    :lists.foldl(fun, acc, collection)
  end

  def reduce(collection, acc, reducer, nil, opts) do
    reduce collection, acc, reducer, reducer, opts
  end

  def reduce(collection, acc, reducer, combiner, opts) when is_list(opts) do
    opts = struct(Enum.Parallel.Opts, opts)
    Reducer.reduce(collection,
                  {:cont, acc},
                  fn x, acc -> {:cont, reducer.(x, acc)} end,
                  fn x, {_, acc} -> {:cont, combiner.(x, acc)} end,
                  opts) |> elem(1)
  end

  def member?(collection, value) when is_list(collection) do
    :lists.member(value, collection)
  end

  def member?(collection, value) do
    Reducer.reduce(collection, {:cont, false}, fn
                    v, _ when v === value -> {:halt, true}
                    _, _                  -> {:cont, false}
                  end) |> elem(1)
  end

  def count(collection) when is_list(collection) do
    :erlang.length(collection)
  end

  def count(collection) do
    Reducer.reduce(collection, {:cont, 0}, fn
                    _, acc -> {:cont, acc + 1}
                  end) |> elem(1)
  end

  def map(collection, fun) do
    combiner = fn x, {_, acc} -> {:cont, x ++ acc} end
    Reducer.reduce(collection, {:cont, []}, R.map(fun), combiner)
      |> elem(1)
      |> :lists.reverse
  end
end
