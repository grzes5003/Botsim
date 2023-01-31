defmodule Observer do
  use Agent

  defmodule Observer.Entry do
    defstruct ping_rcv: 0, ping_sent: 0, ping_passed: 0, msg_passed: 0, dest_unreach: 0
  end

  defstruct node_map: MapSet.new()

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  @spec new :: {:error, any} | {:ok, pid}
  def new do
    init_state = Map.new()
    result = Agent.start_link(fn -> init_state end, name: __MODULE__)
    result
  end

  def tape_bot(id) do
    unless Process.whereis(__MODULE__) == nil,
      do: Agent.update(__MODULE__, &Map.put_new(&1, id, %Observer.Entry{}))
  end

  def inc_counter(id, counter) do
    unless Process.whereis(__MODULE__) == nil do
      Agent.update(__MODULE__, fn state ->
        Map.update(state, id, %Observer.Entry{}, fn entry ->
          Map.update(entry, counter, 0, &(&1 + 1))
        end)
      end)
    end
  end

  def get_counter(id, counter) do
    unless Process.whereis(__MODULE__) == nil do
      Agent.get(__MODULE__, fn state ->
        Map.get(state, id)
        |> Map.get(counter)
      end)
    end
  end

  def sum_counter(counter) do
    unless Process.whereis(__MODULE__) == nil do
      Agent.get(__MODULE__, fn state ->
        state
        |> Enum.map(fn {_, bot} -> Map.get(bot, counter) end)
        |> Enum.sum()
      end)
    end
  end
end
