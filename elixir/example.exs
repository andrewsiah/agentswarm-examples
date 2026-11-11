defmodule TaskFeed do
  def fail(kind, reason) do
    IO.puts(:stderr, "#{kind} error: #{reason}")
    System.halt(1)
  end

  def main do
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    base =
      System.get_env("AGENTSWARM_BASE_URL", "https://agentswarm.space")
      |> String.trim_trailing("/")

    url = String.to_charlist(base <> "/api/feed?type=task")

    tls = [
      verify: :verify_peer,
      cacerts: :public_key.cacerts_get(),
      customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)]
    ]

    body =
      case :httpc.request(:get, {url, []}, [timeout: 15_000, connect_timeout: 15_000, ssl: tls],
             body_format: :binary
           ) do
        {:ok, {{_, status, _}, _, body}} when status in 200..299 -> body
        {:ok, {{_, status, _}, _, _}} -> fail("HTTP", "status #{status}")
        {:error, reason} -> fail("HTTP", inspect(reason))
      end

    lines =
      try do
        %{"items" => items} = :json.decode(body)
        true = is_list(items)

        Enum.flat_map(items, fn
          %{"status" => "open", "id" => id, "title" => title}
          when is_binary(id) and is_binary(title) ->
            [[id, "\t", title, "\t", base, "/p/", id, "\n"]]

          %{"status" => status} when status != "open" ->
            []

          _ ->
            raise ArgumentError, "invalid task row"
        end)
      rescue
        error -> fail("JSON", Exception.message(error))
      end

    IO.write(:stdio, lines)
  end
end

TaskFeed.main()

