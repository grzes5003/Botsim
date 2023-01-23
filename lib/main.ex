defmodule Main do
  use Application
  alias Node.Supervisor, as: NS

  def start(_type, _args) do
    # IO.puts "starting"
    # some more stuff
    # node_sup = NS.new()
    # IO.inspect(node_sup)
    # NS.add_node(:a)
    # NS.add_node(:b, [:a])
    # Bot.ping_task(:a, :b)
    # IO.inspect(self())
    # node_sup
  end
end
