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

  test "test ping" do
    node_sup = NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])

    pid = GenServer.whereis(:b)
    :erlang.trace(pid, true, [:receive])

    assert {:ok, _} = Bot.ping_task(:a, :b)
    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", :ping}}, 2000
  end


  test "test ping no connection" do
    node_sup = NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])
    NS.add_node(:c)

    pid = GenServer.whereis(:c)
    :erlang.trace(pid, true, [:receive])

    assert {:error, "Cannot reach target c"} = Bot.ping_task(:a, :c)
    refute_receive {:trace, ^pid, :receive, {:"$gen_cast", :ping}}, 2000
  end

end
