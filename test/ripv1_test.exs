defmodule RipV1Test do
  use ExUnit.Case

  alias Behaviours.Ping
  alias Routing.Ripv1, as: Rip
  alias Node.Supervisor, as: NS

  test "test neighbors" do
    node_sup = NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])

   Rip.tape_bot(:a)
   Rip.tape_bot(:b)

    assert Bot.neighbours(:a) == [:b]
    assert Bot.neighbours(:b) == [:a]

    assert [%{r_table: [%{addr: :b, age: 0, dist: 0, via: :b}], src: :b}] == Rip.request_table(:a)
  end

  test "test merge table" do
    tables = [
      %{src: :a, r_table: [%{addr: :a, dist: 2}, %{addr: :b, dist: 1}]},
      %{src: :b, r_table: [%{addr: :b, dist: 2}, %{addr: :c, dist: 5}]}
    ]
    own = [%{src: :a,  r_table: [%{addr: :a, dist: 0}, %{addr: :b, dist: 10}]}]

    assert [
      %{addr: :a, dist: 0, via: :a},
      %{addr: :b, dist: 3, via: :b},
      %{addr: :c, dist: 6, via: :b}
    ] == Rip.merge_tables(tables, own)

  end

  test "update tables" do
    NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])

    Rip.tape_bot(:a)
    Rip.tape_bot(:b)

    result = Rip.update_table(:a)

    assert [
      %{addr: :a, age: 0, dist: 0, via: :a},
      %{addr: :b, age: 0, dist: 1, via: :b}
    ] == result[:r_table]
  end

  test "periodic routing" do
    NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])

    Rip.tape_bot(:a)
    Rip.tape_bot(:b)

    Bot.rip_task(:a)

    Process.sleep(3000)
    result = Bot.get(:a)
    assert [
      %{addr: :a, age: 0, dist: 0, via: :a},
      %{addr: :b, age: 0, dist: 1, via: :b}
    ] == result[:r_table]
  end


  test "periodic routing more" do
    NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])
    NS.add_node(:c, [:b])
    NS.add_node(:d, [:b])
    NS.add_node(:e, [:a])
    Process.sleep(100)

    Rip.tape_bot(:a)
    Rip.tape_bot(:b)
    Rip.tape_bot(:c)
    Rip.tape_bot(:d)
    Rip.tape_bot(:e)
    Process.sleep(100)

    Bot.rip_task(:a)
    Process.sleep(100)
    Bot.rip_task(:b)
    Process.sleep(100)
    Bot.rip_task(:c)
    Process.sleep(100)
    Bot.rip_task(:d)
    Process.sleep(100)
    Bot.rip_task(:e)

    Bot.ping_task(:a, :b)
    Bot.ping_task(:d, :b)

    Process.sleep(10000)
    result = Bot.get(:a)
    assert [
      %{addr: :a, age: 0, dist: 0, via: :a},
      %{addr: :b, age: 0, dist: 1, via: :b},
      %{addr: :c, age: 0, dist: 2, via: :b},
      %{addr: :d, age: 0, dist: 2, via: :b},
      %{addr: :e, age: 0, dist: 1, via: :e}
    ] == result[:r_table]
  end

  test "simple ping task" do
    NS.new()
    Observer.new()

    NS.add_node(:a)
    NS.add_node(:b, [:a])
    NS.add_node(:c, [:b])
    NS.add_node(:d, [:b])
    NS.add_node(:e, [:a])
    Process.sleep(100)

    Rip.tape_bot(:a)
    Rip.tape_bot(:b)
    Rip.tape_bot(:c)
    Rip.tape_bot(:d)
    Rip.tape_bot(:e)
    Process.sleep(100)

    Bot.rip_task(:a)
    Process.sleep(100)
    Bot.rip_task(:b)
    Process.sleep(100)
    Bot.rip_task(:c)
    Process.sleep(100)
    Bot.rip_task(:d)
    Process.sleep(100)
    Bot.rip_task(:e)
    Process.sleep(1000)

    Bot.ping_task(:a, :d)
    Process.sleep(Ping.refresh_rate*2)
    assert 1 == Observer.get_counter(:d, :ping_rcv)
  end

end
