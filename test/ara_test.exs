defmodule AraTest do
  use ExUnit.Case

  alias Behaviours.Ping
  alias Routing.Ara, as: Ara
  alias Node.Supervisor, as: NS

  test "test neighbors" do
    node_sup = NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])

    Ara.tape_bot(:a)
    Ara.tape_bot(:b)

    assert Bot.neighbours(:a) == [:b]
    assert Bot.neighbours(:b) == [:a]

    Bot.get_ara_path(:a, :b)
    Process.sleep(200)

    assert MapSet.new([
             %Routing.Ara.Routing.Ara.Entry{
               addr: :b,
               via: :b,
               dist: 1
             }]) == Bot.get(:a) |> Map.get(:r_table)
  end

  test "test distance" do
    node_sup = NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])
    NS.add_node(:c, [:b])
    NS.add_node(:d, [:c])

    Ara.tape_bot(:a)
    Ara.tape_bot(:b)
    Ara.tape_bot(:c)
    Ara.tape_bot(:d)
    Process.sleep(200)

    assert Bot.neighbours(:a) == [:b]

    Bot.get_ara_path(:a, :d)
    Process.sleep(200)

    assert MapSet.new([
             %Routing.Ara.Routing.Ara.Entry{
               addr: :d,
               via: :b,
               dist: 3
             }]) == Bot.get(:a) |> Map.get(:r_table)

    assert MapSet.new([
             %Routing.Ara.Routing.Ara.Entry{
               addr: :a,
               via: :a,
               dist: 2
             },
             %Routing.Ara.Routing.Ara.Entry{
               addr: :d,
               via: :c,
               dist: 2
             }]) == Bot.get(:b) |> Map.get(:r_table)

    assert MapSet.new([
             %Routing.Ara.Routing.Ara.Entry{
               addr: :a,
               via: :b,
               dist: 3
             },
             %Routing.Ara.Routing.Ara.Entry{
               addr: :d,
               via: :d,
               dist: 1
             }]) == Bot.get(:c) |> Map.get(:r_table)

    assert MapSet.new([
             %Routing.Ara.Routing.Ara.Entry{
               addr: :a,
               via: :c,
               dist: 4
             }]) == Bot.get(:d) |> Map.get(:r_table)
  end

  test "test multi path" do
    node_sup = NS.new()
    NS.add_node(:a)

    NS.add_node(:b, [:a])
    NS.add_node(:c, [:b])

    NS.add_node(:d, [:a])

    NS.add_node(:e, [:c, :d])

    Ara.tape_bot(:a)
    Ara.tape_bot(:b)
    Ara.tape_bot(:c)
    Ara.tape_bot(:d)
    Ara.tape_bot(:e)
    Process.sleep(200)

    Bot.get_ara_path(:a, :e)
    Process.sleep(200)

    assert MapSet.new([
             %Routing.Ara.Routing.Ara.Entry{
               addr: :e,
               via: :d,
               dist: 2
             },
             %Routing.Ara.Routing.Ara.Entry{
               addr: :e,
               via: :b,
               dist: 3
             }
           ]) == Bot.get(:a) |> Map.get(:r_table)
  end

  test "simple ping task" do
    NS.new()
    Observer.new()

    NS.add_node(:a)
    NS.add_node(:b, [:a])
    NS.add_node(:c, [:b])
    NS.add_node(:d, [:c])

    Ara.tape_bot(:a)
    Ara.tape_bot(:b)
    Ara.tape_bot(:c)
    Ara.tape_bot(:d)
    Process.sleep(200)

    Observer.tape_bot(:a)
    Observer.tape_bot(:b)
    Observer.tape_bot(:c)
    Observer.tape_bot(:d)
    Process.sleep(200)

    assert Bot.neighbours(:a) == [:b]

    Bot.get_ara_path(:a, :d)
    Process.sleep(200)

    Bot.ping_task(:a, :d)

    Process.sleep(Ping.refresh_rate() * 2)
    assert 1 == Observer.get_counter(:d, :ping_rcv)
  end

  test "multi path ping task" do
    NS.new()
    Observer.new()

    NS.add_node(:a)

    NS.add_node(:b, [:a])
    NS.add_node(:c, [:b])

    NS.add_node(:d, [:a])

    NS.add_node(:e, [:c, :d])

    Ara.tape_bot(:a)
    Ara.tape_bot(:b)
    Ara.tape_bot(:c)
    Ara.tape_bot(:d)
    Ara.tape_bot(:e)
    Process.sleep(200)


    Observer.tape_bot(:a)
    Observer.tape_bot(:b)
    Observer.tape_bot(:c)
    Observer.tape_bot(:d)
    Observer.tape_bot(:e)
    Process.sleep(200)

    Bot.get_ara_path(:a, :e)
    Process.sleep(500)

    Bot.ping_task(:a, :e)

    Process.sleep(Ping.refresh_rate() * 2)
    assert 1 == Observer.get_counter(:e, :ping_rcv)
    assert Observer.get_counter(:e, :ping_rcv) > Observer.get_counter(:c, :ping_rcv)
    Process.sleep(Ping.refresh_rate())
    assert Observer.get_counter(:e, :ping_rcv) > Observer.get_counter(:c, :ping_rcv)
  end
end
