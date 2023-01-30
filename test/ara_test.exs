defmodule AraTest do
  use ExUnit.Case

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

    assert match?(
             %{
               id: :a,
               r_table: [
                 %Routing.Ara.Routing.Ara.Entry{
                   addr: :b,
                   via: :b,
                   ph_val: 1
                 }
               ]
             },
             Bot.get(:a)
           )
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

    assert match?(
             %{
               id: :a,
               r_table: [
                 %Routing.Ara.Routing.Ara.Entry{
                   addr: :d,
                   via: :b,
                   ph_val: 3
                 }
               ]
             },
             Bot.get(:a)
           )

    assert match?(
             %{
               id: :b,
               r_table: [
                 %Routing.Ara.Routing.Ara.Entry{
                   addr: :d,
                   via: :c,
                   ph_val: 2
                 },
                 %Routing.Ara.Routing.Ara.Entry{
                   addr: :a,
                   via: :a,
                   ph_val: 2
                 }
               ]
             },
             Bot.get(:b)
           )

    assert match?(
             %{
               id: :c,
               r_table: [
                 %Routing.Ara.Routing.Ara.Entry{
                   addr: :d,
                   via: :d,
                   ph_val: 1
                 },
                 %Routing.Ara.Routing.Ara.Entry{
                   addr: :a,
                   via: :b,
                   ph_val: 3
                 }
               ]
             },
             Bot.get(:c)
           )

    assert match?(
             %{
               id: :d,
               r_table: [
                 %Routing.Ara.Routing.Ara.Entry{
                   addr: :a,
                   via: :c,
                   ph_val: 4
                 }
               ]
             },
             Bot.get(:d)
           )
  end
end
