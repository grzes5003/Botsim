defmodule Types do
  @type addr :: atom | {:global, any} | {:via, atom, any}
end
