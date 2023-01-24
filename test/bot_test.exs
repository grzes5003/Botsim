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
    NS.add_node(:c, [:b])

    Process.sleep(100)
    add_tables()

    pid = GenServer.whereis(:c)
    :erlang.trace(pid, true, [:receive])

    assert {:ok, _} = Bot.ping_task(:a, :c)
    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:ping, {:a, :c}}}}, 2000
  end


  test "test ping no connection" do
    node_sup = NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])
    NS.add_node(:c)

    pid = GenServer.whereis(:c)
    :erlang.trace(pid, true, [:receive])

    assert {:ok, _} = Bot.ping_task(:a, :c)
    refute_receive {:trace, ^pid, :receive, {:"$gen_cast", {:ping, {:a, :c}}}}, 2000
  end

  def add_tables() do
    entry = [
      %{addr: :a, via: :a, age: 0, dist: 0},
      %{addr: :b, via: :b, age: 0, dist: 1},
      %{addr: :c, via: :b, age: 0, dist: 2},
    ]
    table = %{r_table: entry}
    Bot.tape_state(:a, table)

    entry = [
      %{addr: :b, via: :b, age: 0, dist: 0},
      %{addr: :a, via: :a, age: 0, dist: 1},
      %{addr: :c, via: :c, age: 0, dist: 2},
    ]
    table = %{r_table: entry}
    Bot.tape_state(:b, table)

    entry = [
      %{addr: :c, via: :c, age: 0, dist: 0},
      %{addr: :b, via: :b, age: 0, dist: 1},
      %{addr: :a, via: :b, age: 0, dist: 2},
    ]
    table = %{r_table: entry}
    Bot.tape_state(:c, table)
  end

end
