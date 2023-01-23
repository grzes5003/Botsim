import Config

config :logger, :console,
 format: "[$time][$level][$metadata] $message \n",
 metadata: [:mfa, :registered_name]
