defmodule Morannon do
  use Plug.Builder
  import Plug.Conn

  #plug Plug.Logger

  plug Plug.Session, Application.get_env(:proxy, :session)
  plug :fetch_cookies
  plug :fetch_session
  plug :dispatch

  def start(_argv) do
    IO.puts "Running Proxy with Cowboy on http://localhost:4000"
    Plug.Adapters.Cowboy.http __MODULE__, [], port: 4000, acceptors: 100
    :timer.sleep(:infinity)
  end

  def dispatch(conn, _opts) do
    # Start a request to the client saying we will stream the body.
    # We are simply passing all req_headers forward.
    if session(conn)[:user_token] do
      {:ok, client} = :hackney.request(:get, uri(conn), conn.req_headers, :stream, [])

      conn
      |> write_proxy(client)
      |> read_proxy(client)
    else
      Plug.Conn.send_resp(conn, 200, "unauthorized")
    end
  end

  # Reads the connection body and write it to the
  # client recursively.
  defp write_proxy(conn, client) do
    # Check Plug.Conn.read_body/2 docs for maximum body value,
    # the size of each chunk, and supported timeout values.
    case read_body(conn, []) do
      {:ok, body, conn} ->
        :hackney.send_body(client, body)
        conn
      {:more, body, conn} ->
        :hackney.send_body(client, body)
        write_proxy(conn, client)
    end
  end

  # Reads the client response and sends it back.
  defp read_proxy(conn, client) do
    {:ok, status, headers, client} = :hackney.start_response(client)
    {:ok, body} = :hackney.body(client)

    # Delete the transfer encoding header. Ideally, we would read
    # if it is chunked or not and act accordingly to support streaming.
    #
    # We may also need to delete other headers in a proxy.
    headers = List.keydelete(headers, "Transfer-Encoding", 1)

    %{conn | resp_headers: headers}
    |> send_resp(status, body)
  end

  defp uri(conn) do
    base = target <> "/" <> Enum.join(conn.path_info, "/")
    case conn.query_string do
      "" -> base
      qs -> base <> "?" <> qs
    end
  end

  def target do
    Application.get_env(:proxy, :upstream).address
  end

  def session(conn) do
    Map.get(conn.private, :plug_session)
  end
end
