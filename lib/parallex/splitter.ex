defprotocol Splittable do
	def split(collection)
end

defmodule Splitter do

	def split(collection, opts), do: _split([ collection ], 0, 1, opts.partition_count)

	# If splitting didn't create more fragments, then splitting is done.
	defp _split(fragments, count, count, _n), do: fragments

	# If the split count has been reached, stop splitting.
	defp _split(fragments, _prev_count, count, n) when count >= n, do: fragments

	# Otherwise, split the fragments and recurse.
	defp _split(fragments, _prev_count, count, n) do
		new_splitters = fragments
											|> Enum.reduce([], &split_reducer/2)
											|> Enum.reverse()
		new_count = Enum.count(new_splitters)
		_split new_splitters, count, new_count, n
	end

	defp split_reducer(fragment, acc) do
		case Splittable.split(fragment) do
			[ splitter1, splitter2 ] ->
				[ splitter2, splitter1 | acc ]
			[ splitter1 ] ->
				[ splitter1 | acc ]
			_ ->
				raise ArgumentError, message: "Fragment didn't split as expected: #{inspect fragment}"
		end
	end
end
