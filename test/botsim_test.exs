defmodule BotsimTest do
  use ExUnit.Case
  doctest Botsim

  test "greets the world" do
    assert Botsim.hello() == :world
  end
end
