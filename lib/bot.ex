defmodule Bot do
  @moduledoc """
  Bot API
  """
  @moduledoc since: "1.0.0"

  @behaviour Node

  use GenServer
  require Logger
  alias Routing.Ripv1, as: Rip
  alias Routing.Ara, as: Ara

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
    sch_ref = schedule_ping(id, target)
    {:ok, sch_ref}
  end

  def rip_task(id) do
    Logger.info("starting RIPv1: id=#{id} self=#{inspect(self())}")
    sch_ref = schedule_rip(id)
    {:ok, sch_ref}
  end

  def ara_task(id) do
    Logger.info("starting ARA: id=#{id} self=#{inspect(self())}")
    GenServer.cast(id, :ara)
    sch_ref = schedule_ara(id)
    {:ok, sch_ref}
  end

  def get_ara_path(id, dest) do
    alias Routing.Ara.Routing.Ara.Fant
    fant = Fant.new(id, dest)
    state = Bot.get(id)

    IO.puts("=-=-= #{inspect(self())}")
    Ara.handle_ant(id, state, fant)
  end

  @impl true
  def ping(id, target) do
    Logger.debug("got Ping: id=#{id} target=#{target}")
    :timer.sleep(100)
    Bot.ping(target, id)
  end

  defp schedule_ping(id, target), do:
    Process.send_after(id, {:ping, {id, target}}, Behaviours.Ping.refresh_rate)

  defp schedule_rip(id), do:
    Process.send_after(id, :rip, Rip.refresh_rate)

  defp schedule_ara(id), do:
    Process.send_after(id, :ara, Ara.refresh_rate)

  # ===============

  @impl true
  def handle_call(:neighbours, _from, state) do
    Logger.debug("neighbors call")
    graph = Agent.get(Node.Supervisor, & &1.graph)
    {:reply, :digraph.in_neighbours(graph, _get_id), state}
  end

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call({:update, state}, _from, _), do: {:reply, state, state}

  @impl true
  def handle_info({:ping, {src, target}}, state) do
    Logger.debug("[#{_get_id()}] got info ping from #{src} to #{target}")
    Observer.inc_counter(_get_id(), :ping_sent)
    schedule_ping(_get_id(), target)
    _next(state, target)
    |> elem(1)
    |> IO.inspect()
    |> GenServer.cast({:pass_msg, target, {:ping, {src, target}}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:pass_msg, target, msg}, state) do
    Logger.debug("[#{_get_id()}] :pass_msg #{inspect{msg}} to #{inspect(target)}")
    Observer.inc_counter(_get_id(), :msg_passed)
    if target == _get_id() do
      GenServer.cast(target, msg)
    else
      _next(state, target)
      |> elem(1)
      |>GenServer.cast({:pass_msg, target, msg})
    end
    {:noreply, state}
  end

  @impl true
  def handle_info(:rip, state) do
    id = _get_id()
    schedule_rip(id)
    state = Rip.update_table(id, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:ping, {src, target}}, state) do
    Logger.debug("[#{_get_id()}] got :ping")
    Observer.inc_counter(_get_id(), :ping_rcv)
    {:noreply, state}
  end

  def tape_state(id, state) do
    GenServer.call(id, {:tape_state, state})
  end

  @impl true
  def handle_call({:tape_state, state}, _from, old_state) do
    new_state = Map.merge(old_state, state)
    Logger.debug("taping #{inspect(state)} functionality to id=#{_get_id()} self=#{inspect(self())}")
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast({:fant, fant}, state) do
    Logger.debug("[#{_get_id()}] got fant from #{inspect(fant.from)}")
    {:noreply, Ara.handle_ant(_get_id(), state, fant)}
  end

  @impl true
  def handle_cast({:bant, bant}, state) do
    Logger.debug("[#{_get_id()}] got bant from #{inspect(bant.from)}")
    {:noreply, Ara.handle_ant(_get_id(), state, bant)}
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

  defp _next(state, target) do
    if Map.has_key?(state, :r_table) do
      entry = state.r_table
      |> Enum.filter(fn item -> Map.get(item, :addr) == target end)
      |> Enum.take(1)
      if [] != entry do
        via = Map.get(entry |> hd, :via)
        if !is_nil(via) do
          {:ok, via}
        end
      else
        {:error}
      end
    else
      {:error}
    end
  end

  defp _get_id() do
     {_, id} =  Process.info(self(), :registered_name)
     id
  end

  @spec get_id(pid) :: atom
  def get_id(from) do
    {_, id} =  Process.info(from, :registered_name)
    IO.puts("=== get_id '#{id}'")
    id
 end

  defp _connected(src, target) do
    Bot.neighbours(src)
    |> Enum.member?(target)
  end

end
