# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :proxy, :upstream,
  %{address: System.get_env("UPSTREAM_URL")}

config :proxy, :session,
  store: Plug.Session.Redis,
  key: System.get_env("SESSION_COOKIE"),
  namespace: System.get_env("SESSION_NAMESPACE")

config :hackney, :max_connections, 200
