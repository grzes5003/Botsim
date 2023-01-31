defmodule ExperimentsTest do
  use ExUnit.Case

  alias Behaviours.Ping
  alias Routing.Ara, as: Ara
  alias Routing.Ripv1, as: Rip
  alias Node.Supervisor, as: NS

  defmodule ExperimentsTest.Perf do
    use GenServer

    def start(filename) do
      IO.puts("opening file #{inspect(filename)}")
      {:ok, file} = File.open("resources/results/#{filename}.log", [:write])
      IO.puts("opened file #{inspect(file)}")
      GenServer.start_link(__MODULE__, file, name: __MODULE__)
    end

    def init(state) do
      schedule_work()
      {:ok, state}
    end

    def gracefull_stop() do
      GenServer.cast(__MODULE__, :graceful_stop)

      # GenServer.stop(__MODULE__)
    end

    def handle_cast(:graceful_stop, file) do
      IO.inspect("PID #{inspect(__MODULE__)} received inactivity shutdown. Bye!")
      File.close(file)
      {:stop, :normal, file}
    end

    def handle_info(:work, file) do
      IO.binwrite(file, "dest=#{Observer.sum_counter(:dest_unreach)};ping_rcv=#{Observer.sum_counter(:ping_rcv)};ping_sent=#{Observer.sum_counter(:ping_sent)};msg_passed=#{Observer.sum_counter(:msg_passed)}\n")
      schedule_work()
      {:noreply, file}
    end

    defp schedule_work() do
      Process.send_after(__MODULE__, :work, 100)
    end
  end

  test "network performance ara" do
    setup_network()

    ExperimentsTest.Perf.start("result01")

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

    ExperimentsTest.Perf.gracefull_stop()
  end

  test "network performance rip" do
    setup_network()
    Process.sleep(100)

    ExperimentsTest.Perf.start("result01")

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

    Bot.ping_task(:A, :I)
    Bot.ping_task(:F, :J)

    Process.sleep(10000)

    ExperimentsTest.Perf.gracefull_stop()
    Process.sleep(200)
  end

  def setup_network() do
    NS.new()
    Observer.new()

    NS.update_from_file("test/resources/graph01.txt")
  end



  def perf_measure(filename) do
    {:ok, file} = File.open("resources/results/#{filename}.log", [:write])
    Task.async(fn ->
      obs(file)
    end)
    File.close(file)
  end

  def obs(file, sleep \\ 100,  n \\ 100) do
    IO.binwrite(file, "dest=#{Observer.sum_counter(:dest_unreach)};ping_rcv=#{Observer.sum_counter(:ping_rcv)};ping_sent=#{Observer.sum_counter(:ping_sent)};msg_passed=#{Observer.sum_counter(:msg_passed)}\n")
    Process.sleep(sleep)
    obs(file, sleep, n - 1)
  end

end
