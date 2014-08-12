# defmodule Parallel do
#
#   def processor_count do
#     :erlang.system_info(:logical_processors_available)
#   end
#
#   def scheduler_count do
#     :erlang.system_info(:schedulers_online)
#   end
#
#   defp worker_rpc(pid) do
#   	receive do
#   	  { ^pid, :work, fun, data } ->
#   	    # TODO:
#   	    worker_rpc pid
#   	  { ^pid, :ping } ->
#   	    send pid, { self, :pong }
#   	    worker_rpc pid
#   	  { ^pid, :terminate } ->
#   	    :ok
#   	end
#   end
#
#   def spawn_processes(pid) do
#     Enum.map(1..scheduler_count, fn -> spawn_link(Parallel, :worker_rpc, [ pid ]) end)
#   end
#
#   def mapreduce(collection, acc, mapper, reducer) do
#   pids = spawn_processes self
#     spawn Parallel, :_mapreduce, [ self, pids, collection, acc, mapper, reducer ]
#   end
#
#   defp _mapreduce(pid, pids, collection, acc, mapper, reducer) do
#     Process.flag(:trap_exit, true)
#
#
#
#   end
#
# 	"""
# 	Messages:
# 	{ pid, :work, fun, data }
# 	{ pid, :terminate }
# 	{ pid, :result, data }
# 	{ pid, :ping }
# 	{ pid, :pong }
# 	"""
#
# end
