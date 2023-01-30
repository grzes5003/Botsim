defmodule Routing.Ara do
  alias Routing.Ara.Routing.Ara.Entry
  require Logger
  def decay, do: 100
  def refresh_rate, do: 10000

  defmodule Routing.Ara.Entry do
    defstruct addr: "", via: "", dist: 0
  end

  defmodule Routing.Ara.Fant do
    defstruct type: :fant, uuid: 0, src: 0, dst: 0, hops: 0, from: 0

    def new(id, dst) do
      %Routing.Ara.Fant{uuid:  :erlang.make_ref(), src: id, dst: dst, from: id}
    end
  end

  defmodule Routing.Ara.Bant do
    defstruct type: :bant, uuid: 0, src: 0, dst: 0, hops: 0, from: 0

    def new(id, dst) do
      %Routing.Ara.Bant{uuid:  :erlang.make_ref(), src: id, dst: dst, from: id}
    end
  end

  def tape_bot(id) do
    table = %{r_table: MapSet.new, seen: MapSet.new}
    Bot.tape_state(id, table)
  end

  def seen_uuid?(state, uuid) do
    MapSet.member?(state[:seen], uuid)
  end

  def update_bot(id, state, ant) do
    entry =%Entry{addr: ant.src, via: ant.from, dist: ant.hops + 1}
    table = MapSet.put(state[:r_table], entry)
    seen = MapSet.put(state[:seen], ant.uuid)
    state = %{state | r_table: table,  seen: seen}
    state
  end

  def handle_ant(id, state, %{type: :fant, dst: dst} = fant) when id == dst do
    state = update_bot(id, state, fant)
    graph = Agent.get(Node.Supervisor, & &1.graph)
      :digraph.in_neighbours(graph, id)
      |> Enum.map(fn n_id ->
        bant = Routing.Ara.Bant.new(id, dst)
        GenServer.cast(n_id, {:bant, bant})
        Logger.debug("#{id} relayed fant to #{n_id}")
      end)
    state
  end

  def handle_ant(id, state, %{type: :bant, dst: dst} = bant) when id == dst do
    state = update_bot(id, state, bant)
    Logger.debug("[#{id}] completed routing from #{id} to #{bant.src}")
    state
  end

  def handle_ant(id, state, ant) do
    if seen_uuid?(state, ant.uuid) do
      Logger.debug("[#{id}] got already seen fant from #{inspect(ant.from)}")
      state
    else
      state = update_bot(id, state, ant)
      graph = Agent.get(Node.Supervisor, & &1.graph)
      :digraph.in_neighbours(graph, id)
      |> Enum.filter(& &1 != ant.from)
      |> Enum.map(fn n_id ->
        ant = %{ant | hops: ant.hops + 1, from: id}
        GenServer.cast(n_id, {ant.type, ant})
        Logger.debug("#{id} relayed fant to #{n_id}")
      end)
      state
    end
  end

end
