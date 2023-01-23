defmodule BotTest do
  use ExUnit.Case
  doctest Bot

  alias Node.Supervisor, as: NS

  test "test neighbors" do
    node_sup = NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])
    assert Bot.neighbours(:a) == [:b]
    assert Bot.neighbours(:b) == [:a]
  end

  # @tag :skip
  test "test ping" do
    node_sup = NS.new()
    IO.inspect(node_sup)
    NS.add_node(:a)
    NS.add_node(:b, [:a])
    ref = Process.monitor(:a)
    assert {:ok, _} = Bot.ping_task(:a, :b)
    IO.inspect(self())
    assert_receive {:DOWN, ^ref, :process, _object, :normal}, 2000
    assert false
  end

  @tag :skip
  test "test ping no connection" do
    node_sup = NS.new()
    NS.add_node(:a)
    NS.add_node(:c, [:a])
    NS.add_node(:b, [:a])
    Bot.ping_task(:a, :c)
  end

end
