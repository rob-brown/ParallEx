defprotocol ParallelEnumerable do

  @type acc :: {:cont, term} | {:halt, term} | {:suspend, term}
  @type reducer :: (term, term -> acc)
  @type combiner :: (term, term -> acc)
  @type continuation :: (acc -> result)
  @type result :: {:done, term} | {:halted, term} | {:suspended, term, continuation}

  def count(collection);
  def member?(collection, value);
  def reduce(collection, acc, reducer, combiner, partitions);
end

defmodule ParallelEnum do

  @default_partition_size 512

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

  # ???: Should I instead have an `options` list instead of partitions?
  def reduce(collection, acc, fun, combiner \\ nil, partitions \\ @default_partition_size)

  def reduce(collection, acc, fun, _combiner, _partitions) when is_list(collection) do
    :lists.foldl(fun, acc, collection)
  end

  def reduce(collection, acc, reducer, nil, partitions) do
    reduce(collection, acc, reducer, reducer, partitions)
  end

  def reduce(collection, acc, reducer, combiner, partitions) do
    ParallelEnumerable.reduce(collection,
                              {:cont, acc},
                              fn x, acc -> {:cont, reducer.(x, acc)} end,
                              fn x, {_, acc} -> {:cont, combiner.(x, acc)} end,
                              partitions) |> elem(1)
  end

  def member?(collection, value) when is_list(collection) do
    :lists.member(value, collection)
  end

  def member?(collection, value) do
    case ParallelEnumerable.member?(collection, value) do
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
    case ParallelEnumerable.count(collection) do
      {:ok, value} when is_integer(value) ->
        value
      {:error, module} ->
        module.reduce(collection, {:cont, 0}, fn
          _, acc -> {:cont, acc + 1}
        end) |> elem(1)
    end
  end

  def map(collection, fun) do
    combiner = fn x, {_, acc} -> {:cont,  x ++ acc} end
    ParallelEnumerable.reduce(collection, {:cont, []}, R.map(fun), combiner, @default_partition_size)
      |> elem(1)
      |> :lists.reverse
  end
end
