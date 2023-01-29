defmodule Routing.Ara do
  alias Routing.Ara.Routing.Ara.Entry
  require Logger
  def decay, do: 100
  def refresh_rate, do: 10000

  defmodule Routing.Ara.Entry do
    defstruct addr: "", via: "", ph_val: 0
  end

  defmodule Routing.Ara.Fant do
    defstruct type: :fant, uuid: 0, src: 0, dst: 0, hops: 0

    def new(id) do
      %Routing.Ara.Fant{uuid:  :erlang.make_ref(), src: id}
    end
  end

  defmodule Routing.Ara.Bant do
    defstruct type: :bant, uuid: 0, src: 0, dst: 0, hops: 0

    def new(id) do
      %Routing.Ara.Bant{uuid:  :erlang.make_ref(), src: id}
    end
  end

  def tape_bot(id) do
    table = %{r_table: [], seen: MapSet.new}
    Bot.tape_state(id, table)
  end

  def seen_uuid?(state, uuid) do
    MapSet.member?(state[:seen], uuid)
  end

  def update_bot(id, state, from, ant) do
    IO.puts("===========")
    IO.inspect(id)
    IO.inspect(ant.src)
    IO.puts("===========")
    entry =%Entry{addr: ant.src, via: Bot.get_id(from), ph_val: ant.hops + 1}
    IO.inspect(state[:r_table])
    IO.inspect(entry)
    IO.inspect(Bot.get_id(from))
    table = [entry | state[:r_table]]
    seen = MapSet.put(state[:seen], ant.uuid)
    state = %{state | r_table: table,  seen: seen}
    IO.inspect(state[:r_table])
    state
  end

  def handle_ant(id, state, from, %{type: :fant, dst: dst} = fant) when id == dst do
    state = update_bot(id, state, from, fant)
    IO.inspect(state)
    graph = Agent.get(Node.Supervisor, & &1.graph)
      :digraph.in_neighbours(graph, id)
      |> Enum.filter(& &1 != Bot.get_id(from))
      |> Enum.map(fn n_id ->
        bant = Routing.Ara.Bant.new(id)
        GenServer.call(n_id, {:bant, bant})
        Logger.debug("#{id} relayed fant to #{n_id}")
      end)
    state
  end

  def handle_ant(id, state, from, %{type: :bant, dst: dst} = bant) when id == dst do
    state = update_bot(id, state, from, bant)

    graph = Agent.get(Node.Supervisor, & &1.graph)
      :digraph.in_neighbours(graph, id)
      |> Enum.filter(& &1 != Bot.get_id(from))
      |> Enum.map(fn n_id ->
        bant = Routing.Ara.Bant.new(id)
        GenServer.call(n_id, {:bant, bant})
        Logger.debug("#{id} relayed fant to #{n_id}")
      end)
    state
  end

  def handle_ant(id, state, from, ant) do
    if seen_uuid?(state, ant.uuid) do
      Logger.debug("#{id} got already seen fant from #{inspect(from)}")
      state
    else
      IO.puts("==== handle_ant ==== #{id}")
      state = update_bot(id, state, from, ant)
      graph = Agent.get(Node.Supervisor, & &1.graph)
      :digraph.in_neighbours(graph, id)
      |> Enum.filter(& &1 != Bot.get_id(from))
      |> Enum.map(fn n_id ->
        ant = %{ant | hops: ant.hops + 1}
        GenServer.call(n_id, {ant.type, ant})
        Logger.debug("#{id} relayed fant to #{n_id}")
      end)
      state
    end
  end

end
