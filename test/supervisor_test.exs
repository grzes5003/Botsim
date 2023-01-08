defmodule SupervisorTest do
  use ExUnit.Case
  doctest Node.Supervisor

  alias Node.Supervisor, as: NS

  test "create node" do
    node_sup = NS.new()
    NS.add_node(:node01)
    assert NS.get_nodes() == [:node01]
    IO.inspect(NS.get_edges())
    assert Agent.get(:node01, & &1) == %Bot {}
  end

  test "create edge" do
    node_sup = NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])
    assert :sets.from_list(NS.get_nodes()) == :sets.from_list([:a, :b])
    assert :sets.from_list(Agent.get(NS, &:digraph.vertices(&1.graph))) ==
             :sets.from_list([:a, :b])
  end

  test "create agents" do
    node_sup = NS.new()
    NS.add_node(:node01)
    assert NS.get_nodes() == [:node01]
    IO.inspect(NS.get_edges())
  end

  test "read from file" do
    node_sup = NS.new()
    NS.update_from_file("test/resources/graph_test.txt")

    assert NS.get_nodes() |> length() == 4
    assert NS.get_edges() |> length() == 8
  end
end
