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

    ExperimentsTest.Perf.start("result02")

    Ara.tape_to_all()
    Process.sleep(200)

    Bot.ping_task(:A, :I)
    Bot.ping_task(:F, :J)

    Bot.get_ara_path(:A, :I)
    Bot.get_ara_path(:F, :J)
    Process.sleep(10000)

    Bot.get_ara_path(:E, :D)
    Bot.get_ara_path(:F, :J)

    Bot.ping_task(:E, :D)
    Bot.ping_task(:F, :J)

    Process.sleep(30000)

    ExperimentsTest.Perf.gracefull_stop()
    Process.sleep(200)
  end

  test "network performance rip" do
    setup_network()
    Process.sleep(100)

    ExperimentsTest.Perf.start("result01")

    Rip.tape_to_all()
    Rip.rip_task_to_all()

    Bot.ping_task(:A, :I)
    Bot.ping_task(:F, :J)

    Process.sleep(10000)

    Bot.ping_task(:E, :D)
    Bot.ping_task(:H, :A)

    Process.sleep(30000)

    ExperimentsTest.Perf.gracefull_stop()
    Process.sleep(200)
  end

  test "network performance rip with timeouts" do
    setup_network()
    Process.sleep(100)

    ExperimentsTest.Perf.start("result01_t")

    Rip.tape_to_all()
    Rip.rip_task_to_all()

    Bot.ping_task(:A, :I)
    Bot.ping_task(:F, :J)

    Process.sleep(10000)

    Bot.ping_task(:E, :D)
    Bot.ping_task(:H, :A)

    Process.sleep(10000)
    NS.remove(:C)
    Process.sleep(10000)
    NS.remove(:B)
    Process.sleep(10000)

    ExperimentsTest.Perf.gracefull_stop()
    Process.sleep(200)
  end

  test "network performance ara with timeouts" do
    setup_network()

    ExperimentsTest.Perf.start("result02_t")

    Ara.tape_to_all()
    Process.sleep(200)

    Bot.ping_task(:A, :I)
    Bot.ping_task(:F, :J)

    Bot.get_ara_path(:A, :I)
    Bot.get_ara_path(:F, :J)
    Process.sleep(10000)

    Bot.get_ara_path(:E, :D)
    Bot.get_ara_path(:F, :J)

    Bot.ping_task(:E, :D)
    Bot.ping_task(:F, :J)

    Process.sleep(10000)
    NS.remove(:C)
    Process.sleep(10000)
    NS.remove(:B)
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
