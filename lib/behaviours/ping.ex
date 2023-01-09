defmodule Behaviours.Ping do
  @callback ping_task(Types.addr, Types.addr) :: {:ok} | {:error, String.t}

  @callback ping(Types.addr, Types.addr) :: any
end
