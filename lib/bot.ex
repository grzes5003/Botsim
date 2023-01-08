defmodule Bot do
  @behaviour Node
  use Agent

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
    :digraph.edges(graph, id)
  end


  def value(id) do
    Agent.get(id, & &1)
  end

  def increment(id) do
    Agent.update(id, &(&1 + 1))
  end
end
