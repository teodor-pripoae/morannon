defmodule TestPlug do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _opts) do
    {a1,a2,a3} = :erlang.now()
    :random.seed({a1, a2, a3})
    if :random.uniform > 0.5 do
      new_c = Map.put(%{}, "_kuende_session", "361e2dfac2866500bcdafa6b60ced545")
      new_cookies = Map.merge(conn.cookies, new_c)
      conn = Map.put(conn, :cookies, new_cookies)
    else
      conn
    end
  end
end
