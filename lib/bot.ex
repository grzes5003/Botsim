defmodule Bot do
  @moduledoc """
  Bot API
  """
  @moduledoc since: "1.0.0"

  @behaviour Node

  use GenServer
  require Logger

  defstruct id: "", infected: false

  def start_link(id, initial_value) do
    GenServer.start_link(Bot, initial_value, name: id)
  end

  @impl true
  def init(init_state) do
    {:ok, init_state}
  end

  # Node behaviour

  @impl true
  def new(id), do: GenServer.start_link(Bot, %{id: id}, name: id)

  def call(id, msg) do
    GenServer.call(id, msg)
  end

  @impl true
  def neighbours(id), do: GenServer.call(id, :neighbours)

  @impl true
  def get(id), do: GenServer.call(id, :get)

  def update(id, state),  do: GenServer.call(id, {:update, state})

  @impl true
  def pass_msg(next, payload), do:
    GenServer.call(next, payload)

  # ===============
  @behaviour Behaviours.Ping

  @doc """
  ping some `target` from node with `id`

  Returns `{:ok, scheduler_reference}`
  """
  @impl true
  def ping_task(id, target) do
    Logger.info("starting Ping: id=#{id} target=#{target} self=#{inspect(self())}")
    case _connected(id, target) do
      true ->
        sch_ref = schedule_ping(id, target)
        {:ok, sch_ref}
      false ->
        {:error, "Cannot reach target #{target}"}
    end
  end

  @impl true
  def ping(id, target) do
    Logger.debug("got Ping: id=#{id} target=#{target}")
    :timer.sleep(100)
    Bot.ping(target, id)
  end

  defp schedule_ping(id, target), do:
    Process.send_after(id, {:ping, {target}}, 1000)

  # ===============

  @impl true
  def handle_call(:neighbours, _from, state) do
    graph = Agent.get(Node.Supervisor, & &1.graph)
    {:reply, :digraph.in_neighbours(graph, _get_id), state}
  end

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call({:update, state}, _from, _), do: {:reply, state, state}

  @impl true
  def handle_info({:ping, {target}}, state) do
    Logger.debug("got info ping to #{target}")
    schedule_ping(_get_id(), target)
    if target == _get_id() do
      GenServer.cast(target, :ping)
    else
      _next(state, target)
      |> GenServer.cast({:pass_msg, target, :ping})
    end
    {:noreply, state}
  end

  @impl true
  def handle_cast({:pass_msg, target, msg}, state) do
    Logger.debug(":pass_msg #{inspect{msg}} to #{inspect(target)}")
    if target == _get_id() do
      GenServer.cast(target, msg)
    else
      _next(state, target)
      |>GenServer.cast({:pass_msg, target, msg})
    end
    {:noreply, state}
  end

  @impl true
  def handle_cast(:ping, state) do
    Logger.debug("got :ping")
    {:noreply, state}
  end

  def tape_state(id, state) do
    GenServer.call(id, {:tape_state, state})
  end

  @impl true
  def handle_call({:tape_state, state}, _from, old_state) do
    new_state = Map.merge(old_state, state)
    IO.inspect(new_state)
    IO.puts("updating")
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(msg, _from, state) do
    Logger.warn("GOT UNEXPECTED MSG #{inspect(msg)}")
    {:reply, :wtf, state}
  end

  def handle_info(:alive, state) do
    IO.puts("alive!")
    {:noreply, state}
  end

  # =============== util

  defp _next(_, target), do: target

  defp _get_id() do
     {_, id} =  Process.info(self(), :registered_name)
     id
  end

  defp _connected(src, target) do
    Bot.neighbours(src)
    |> Enum.member?(target)
  end

end
