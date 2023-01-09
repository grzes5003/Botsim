defmodule Bot do
  @behaviour Node

  use Agent
  require Logger

  defstruct id: "", infected: false

  def start_link(id, initial_value) do
    Agent.start_link(fn -> initial_value end, name: id)
  end

  # Node behaviour

  def new(id) do
    Agent.start_link(fn -> %Bot{} end, name: id)
  end

  def neigbhours(id) do
    graph = Agent.get(Node.Supervisor, & &1.graph)
    :digraph.in_neighbours(graph, id)
  end

  @impl true
  def _connected(src, target) do
    Bot.neigbhours(src)
    |> Enum.member?(target)
  end

  # ===============
  @behaviour Behaviours.Ping

  @impl true
  def ping_task(id, target) do
    Logger.info("starting Ping: id=#{id} target=#{target}")
    case Bot._connected(id, target) do
      true ->
        Bot.ping(id, target)
        {:ok}
      false ->
        {:error, "Cannot reach target #{target}"}
    end
  end

  @impl true
  def ping(id, target) do
    Logger.info("got Ping: id=#{id} target=#{target}")
    :timer.sleep(100)
    Bot.ping(target, id)
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 2 * 1000)
  end

  # ===============

  def value(id) do
    Agent.get(id, & &1)
  end

  def increment(id) do
    Agent.update(id, &(&1 + 1))
  end


end
