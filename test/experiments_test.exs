defmodule ExperimentsTest do
  use ExUnit.Case

  alias Behaviours.Ping
  alias Routing.Ara, as: Ara
  alias Routing.Ripv1, as: Rip
  alias Node.Supervisor, as: NS

  test "network performance ara" do
    setup_network()

    Ara.tape_bot(:A)
    Ara.tape_bot(:B)
    Ara.tape_bot(:C)
    Ara.tape_bot(:D)
    Ara.tape_bot(:E)
    Ara.tape_bot(:F)
    Ara.tape_bot(:G)
    Ara.tape_bot(:H)
    Ara.tape_bot(:I)
    Ara.tape_bot(:J)

    Bot.get_ara_path(:A, :I)
    Process.sleep(200)

  end

  test "network performance rip" do
    setup_network()

    Rip.tape_bot(:A)
    Rip.tape_bot(:B)
    Rip.tape_bot(:C)
    Rip.tape_bot(:D)
    Rip.tape_bot(:E)
    Rip.tape_bot(:F)
    Rip.tape_bot(:G)
    Rip.tape_bot(:H)
    Rip.tape_bot(:I)
    Rip.tape_bot(:J)

    Process.sleep(200)
    Bot.rip_task(:A)
    Process.sleep(100)
    Bot.rip_task(:B)
    Process.sleep(100)
    Bot.rip_task(:C)
    Process.sleep(100)
    Bot.rip_task(:D)
    Process.sleep(100)
    Bot.rip_task(:E)
    Process.sleep(100)
    Bot.rip_task(:F)
    Process.sleep(100)
    Bot.rip_task(:G)
    Process.sleep(100)
    Bot.rip_task(:H)
    Process.sleep(100)
    Bot.rip_task(:H)
    Process.sleep(100)
    Bot.rip_task(:I)
    Process.sleep(100)
    Bot.rip_task(:J)
    Process.sleep(5000)

    Bot.ping_task(:A, :I)
    Bot.ping_task(:F, :J)

    Process.sleep(5000)

    assert 4 == Observer.get_counter(:J, :ping_rcv)
  end

  def setup_network() do
    NS.new()
    Observer.new()

    NS.update_from_file("test/resources/graph01.txt")
  end

end
