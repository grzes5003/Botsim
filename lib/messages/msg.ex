defmodule Msg do
  @type raw_msg :: String.t

  @type ping :: {Types.addr, Types.addr}

  @type direct_msg :: {Types.addr, Types.addr, String.t}
end
