defmodule Routing.Ripv1 do
  use GenServer
  require Logger

  def refresh_rate, do: 1000

  # every 30 secs send req to neighbors for routing table
  defmodule Routing.Ripv1.Entry do
    defstruct addr: "", via: "", age: 0, dist: 0
  end

  defstruct r_table: []

  def start_link(id, initial_value) do
    Bot.start_link(id, initial_value)
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  def tape_bot(id) do
    entry = %{addr: id, via: id, age: 0, dist: 0}
    table = %{r_table: [entry]}
    Bot.tape_state(id, table)
  end

  def tape_to_all() do
    Node.Supervisor.get_nodes()
    |> Enum.each(& tape_bot(&1))
  end

  def rip_task_to_all() do
    Node.Supervisor.get_nodes()
    |> Enum.each(fn id ->
      Bot.rip_task(id)
      Process.sleep(100)
    end)
  end

  def request_table(id) do
      Bot.neighbours(id)
      |> Enum.map(fn n_id -> Map.merge(%{src: n_id}, Bot.get(n_id)) end)
      |> Enum.map(fn state -> %{src: state.src, r_table: state[:r_table]} end)
  end

  def request_table(id, _) do
    graph = Agent.get(Node.Supervisor, & &1.graph)
    :digraph.in_neighbours(graph, id)
    |> Enum.map(fn n_id ->
      Logger.debug("#{id} asked for neighbor #{n_id}")
      Map.merge(%{src: n_id}, Bot.get(n_id))
    end)
    |> Enum.map(fn state -> %{src: state.src, r_table: state[:r_table]} end)
end

  def update_table(id) do
    IO.puts("upd_table #{id}")
    state = Bot.get(id)
    own = [%{src: id, r_table: state[:r_table]}]

    table = request_table(id)
    |> merge_tables(own)

    Bot.update(id, %{state | r_table: table})
  end

  def update_table(id, state) do
    IO.puts("upd_table/2 #{id}")
    own = [%{src: id, r_table: state[:r_table]}]

    table = request_table(id, state)
    |> merge_tables(own)

    %{state | r_table: table}
  end

  @impl true
  def handle_call(:request_tables, _from, state) do
    {:reply, state.r_table , state}
  end

  def merge_tables(tables, own) do
    addr = Kernel.hd(own)
    |> Map.get(:src)

    foreign_tables = tables
    |> prepare_table
    |> Enum.map(fn entry -> %{entry | dist: entry[:dist] + 1 } end)

    (own |> prepare_table) ++ foreign_tables
    |> Enum.group_by(fn entry -> entry[:addr] end)
    |> Enum.map(fn {_, group} ->
      group
      |> Enum.filter(&(&1[:dist] <= 15))
      |> Enum.filter(&(&1[:addr] == addr || &1[:via] != addr))
      |> Enum.sort(&(&1[:dist] <= &2[:dist]))
      |> Enum.take(1)
    end)
    |> Enum.flat_map(fn x -> x end)
  end

  # addr != own && via == own

  def prepare_table(table) do
    table
    |> Enum.map(fn entry ->
      entry[:r_table]
      |> Enum.map(fn row -> Map.merge(row, %{via: entry[:src]}) end)
    end)
    |> Enum.flat_map(fn x -> x end)
  end
end
