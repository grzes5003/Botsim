defmodule Node.Supervisor do
  # alias Inspect.Stream

  use Agent
  require Logger

  defstruct graph: nil, nodes: []


  @spec start_link(Node.Supervisor) :: {:error, any} | {:ok, pid}
  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  @spec new :: {:error, any} | {:ok, pid}
  def new do
    init_state = %__MODULE__ {}
    result = Agent.start_link(fn -> init_state end, name: __MODULE__)
    Agent.update(__MODULE__, fn state -> %{state | graph: :digraph.new} end)
    IO.inspect(self())
    result
  end

  @spec add_node(Types.addr, [Types.addr]) :: :ok
  def add_node(name, neighbours) do
    Agent.update(__MODULE__, fn state -> _add_node(state, name, neighbours) end)
  end

  @spec add_node(Types.addr) :: :ok
  def add_node(name) do
    Agent.update(__MODULE__, fn state -> _add_node(state, name, []) end)
  end

  @spec add_edge(Types.addr, Types.addr) :: :ok
  def add_edge(a, b) do
    Agent.update(__MODULE__, fn state -> _add_edge(state, a, b) end)
  end

  @spec get_nodes :: [String.t]
  def get_nodes do
    Agent.get(__MODULE__, & &1.nodes)
  end

  @spec get_edges :: any
  def get_edges do
    Agent.get(__MODULE__, & :digraph.edges(&1.graph))
  end

  @spec update_from_file(String.t) :: none
  def update_from_file(file_path) do
    file = File.open!(file_path, [:read, :utf8])
    input = IO.read(file, :all) |> String.split("\n")

    [verts, edges] = input
    |> _get_chunks()

    verts
    |> Enum.map(fn sub -> String.split(sub, ",", trim: true) end)
    |> List.flatten
    |> Enum.map(fn sub -> String.to_atom(sub) end)
    |> Enum.map(fn sub -> __MODULE__.add_node(sub) end)

    edges
    |> Enum.map(fn sub -> String.split(sub, "-", trim: true) end)
    |> Enum.map(fn [a,b] ->
      a = String.to_atom(a)
      b = String.to_atom(b)
      __MODULE__.add_edge(a,b)
      __MODULE__.add_edge(b,a)
    end)
  end

  ### internal

  def _add_node(state, name, neighbours) do
    Logger.debug("Adding new node name=#{name}, neigh=#{inspect(neighbours)}")
    :digraph.add_vertex(state.graph, name)
    neighbours
    |> Enum.each(fn nei ->
      :digraph.add_edge(state.graph, name, nei)
      :digraph.add_edge(state.graph, nei, name)
    end)
    children = [
      %{
        id: name,
        start: {Bot, :start_link, [name, %Bot{id: name}]},
        shutdown: :infinity,
        restart: :temporary
      }
    ]
    # Bot.new(name)
    Supervisor.start_link(children, strategy: :one_for_one)
    %{state | nodes: [name | state.nodes]}
  end

  def _add_edge(state, a, b) do
    :digraph.add_edge(state.graph, a, b)
    state
  end

  ### Util

  def _get_chunks(list) do
    list
    |> Enum.chunk_by(fn x -> x != "" end)
    |> Enum.reject(fn x -> x == [""] end)
  end
end
