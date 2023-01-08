defmodule Node do
  @type id :: atom | {:global, any} | {:via, atom, any}

  @callback send(pid, Msg.msg) :: {:ok, String.t} | {:error, String.t}

  @callback rcv(pid) :: String.t

  @callback neigbhours(String.t) :: [String.t]

  @callback find_neigh(pid) :: [pid]

  @callback new(id) :: {:error, any} | {:ok, pid}
end
