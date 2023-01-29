defmodule Node do
  @callback send(pid, Msg.msg) :: {:ok, String.t} | {:error, String.t}

  @callback rcv(pid) :: String.t

  @callback neighbours(String.t) :: [String.t]

  @callback _connected(Types.addr, Types.addr) :: boolean

  @callback find_neigh(pid) :: [pid]

  @callback new(Types.addr) :: {:error, any} | {:ok, pid}

  @callback get(Types.addr) :: {:error, any} | {:ok, any}

  @callback pass_msg(Types.addr, Msg.msg) :: {:error, any} | {:ok, pid}

  @callback disjoint(Types.addr, Types.addr) :: {:error, any} | {:ok}

  @callback disable(Type.addr) :: {:error, any} | {:ok}
end
