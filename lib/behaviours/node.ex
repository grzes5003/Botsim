defmodule Node do
  @callback send(pid, Msg.msg) :: {:ok, String.t} | {:error, String.t}

  @callback rcv(pid) :: String.t

  @callback neigbhours(String.t) :: [String.t]

  @callback _connected(Types.addr, Types.addr) :: boolean

  @callback find_neigh(pid) :: [pid]

  @callback new(Types.addr) :: {:error, any} | {:ok, pid}
end
