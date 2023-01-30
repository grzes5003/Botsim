defmodule ObserverTest do
  use ExUnit.Case

  alias Behaviours.Ping
  alias Node.Supervisor, as: NS


  test "test ping counter" do
    result = Observer.new()
    assert result = {:ok}

    NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])
    NS.add_node(:c, [:b])

    Observer.tape_bot(:a)
    Observer.tape_bot(:b)
    Observer.tape_bot(:c)

    Process.sleep(100)
    add_tables()

    assert {:ok, _} = Bot.ping_task(:a, :c)

    Process.sleep(Ping.refresh_rate*2)
    assert 1 == Observer.get_counter(:c, :ping_rcv)

    Process.sleep(Ping.refresh_rate)
    assert 2 == Observer.get_counter(:c, :ping_rcv)
    assert 2 == Observer.get_counter(:c, :msg_passed)
    assert 0 == Observer.get_counter(:b, :ping_rcv)
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
