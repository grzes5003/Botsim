defmodule Behaviours.Ping do
  def refresh_rate, do: 1000

  @callback ping_task(Types.addr, Types.addr) :: {:ok} | {:error, String.t}

  @callback ping(Types.addr, Types.addr) :: any
end
