defmodule Bot do
  @behaviour Node

  use GenServer
  require Logger

  defstruct id: "", infected: false

  def start_link(id, initial_value), do:
    GenServer.start_link(Bot, initial_value, name: id)

  @impl true
  def init(init_state) do
    {:ok, init_state}
  end

  # Node behaviour

  @impl true
  def new(id), do: GenServer.start_link(Bot, %Bot{id: id}, name: id,)

  @impl true
  def neighbours(id), do: GenServer.call(id, :neighbours)

  @impl true
  def get(id), do: GenServer.call(id, :get)

  @impl true
  def pass_msg(next, payload), do:
    GenServer.call(next, payload)

  # ===============
  @behaviour Behaviours.Ping

  @impl true
  def ping_task(id, target) do
    Logger.info("starting Ping: id=#{id} target=#{target} self=#{inspect(self())}")
    IO.inspect(self())
    case _connected(id, target) do
      true ->
        sch_ref = schedule_ping(target)
        {:ok, sch_ref}
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

  defp schedule_ping(target) do
    IO.puts("starting ping")
    # GenServer.call(self(), {:alive})
    # a = Process.send_after(self(), {:pass_msg, {target, :ping}}, 10)
    a = Process.send_after(self(), :alive, 15)
    IO.puts(Process.read_timer(a))
  end

  # ===============

  @impl true
  def handle_call(:neighbours, _from, state) do
    graph = Agent.get(Node.Supervisor, & &1.graph)
    {:reply, :digraph.in_neighbours(graph, _get_id), state}
  end

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call({:pass_msg, {target, msg}}, _from, state) do
    IO.puts("got handle")
    IO.inspect(msg)
    if target == _get_id() do
      GenServer.call(self(), msg)
    else
      _next(state, target)
      |> pass_msg({target, msg})
    end
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    IO.puts(":rcv_ping")
    {:reply, :ok, state}
  end

  def handle_info(:alive, _from, state) do
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
