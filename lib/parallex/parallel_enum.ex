defmodule Enum.Parallel.Opts do

  defstruct partition_count: 512,
            timeout: :infinity

  @type t :: %__MODULE__{
    partition_count: pos_integer,
    timeout: pos_integer | :infinity
  }
end

defprotocol Enumerable.Parallel do

  @type acc :: {:cont, term} | {:halt, term} | {:suspend, term}
  @type reducer :: (term, term -> acc)
  @type combiner :: (term, term -> acc)
  @type continuation :: (acc -> result)
  @type result :: {:done, term} | {:halted, term} | {:suspended, term, continuation}

  def count(collection);
  def member?(collection, value);
  def reduce(collection, acc, reducer, combiner, opts \\ %Enum.Parallel.Opts{});
end

defmodule Enum.Parallel do

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
    Enumerable.Parallel.reduce(collection,
                              {:cont, acc},
                              fn x, acc -> {:cont, reducer.(x, acc)} end,
                              fn x, {_, acc} -> {:cont, combiner.(x, acc)} end,
                              opts) |> elem(1)
  end

  def member?(collection, value) when is_list(collection) do
    :lists.member(value, collection)
  end

  def member?(collection, value) do
    case Enumerable.Parallel.member?(collection, value) do
      {:ok, value} when is_boolean(value) ->
        value
      {:error, module} ->
        module.reduce(collection, {:cont, false}, fn
          v, _ when v === value -> {:halt, true}
          _, _                  -> {:cont, false}
        end) |> elem(1)
    end
  end

  def count(collection) when is_list(collection) do
    :erlang.length(collection)
  end

  def count(collection) do
    case Enumerable.Parallel.count(collection) do
      {:ok, value} when is_integer(value) ->
        value
      {:error, module} ->
        module.reduce(collection, {:cont, 0}, fn
          _, acc -> {:cont, acc + 1}
        end) |> elem(1)
    end
  end

  def map(collection, fun) do
    combiner = fn x, {_, acc} -> {:cont, x ++ acc} end
    Enumerable.Parallel.reduce(collection, {:cont, []}, R.map(fun), combiner)
      |> elem(1)
      |> :lists.reverse
  end
end
