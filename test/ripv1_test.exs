defmodule RipV1Test do
  use ExUnit.Case

  alias Routing.Ripv1, as: Rip
  alias Node.Supervisor, as: NS

  test "test neighbors" do
    node_sup = NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])

    IO.inspect(Rip.tape_bot(:a))

    assert Bot.neighbours(:a) == [:b]
    assert Bot.neighbours(:b) == [:a]

    IO.inspect(Rip.request_table(:a))
    flunk "ASd"
  end

  test "test merge table" do
    tables = [
      %{src: :a, r_state: [%{addr: :a, dist: 1}, %{addr: :b, dist: 1}]},
      %{src: :b, r_state: [%{addr: :b, dist: 2}, %{addr: :c, dist: 5}]}
    ]
    own = [%{src: :x,  r_state: [%{addr: :a, dist: 0}, %{addr: :b, dist: 10}]}]

    assert [
      %{addr: :a, dist: 0, via: :x},
      %{addr: :b, dist: 2, via: :a},
      %{addr: :c, dist: 6, via: :b}
    ] == Rip.merge_tables(tables, own)

  end

  test "update tables" do
    NS.new()
    NS.add_node(:a)
    NS.add_node(:b, [:a])

    Rip.tape_bot(:a)
    Rip.tape_bot(:b)

    Rip.update_table(:a)
  end

end
