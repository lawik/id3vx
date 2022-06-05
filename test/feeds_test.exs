defmodule Id3vx.FeedTest do
  use ExUnit.Case
  require Logger

  @feeds [
    "https://atp.fm/rss"
  ]
  @path "/tmp"
  @tag timeout: :infinity
  test "pull podcast RSS feeds pull their MP3s and parse" do
    feeds =
      Stream.map(
        @feeds,
        fn url ->
          IO.puts("Parsing feed at: #{url}")
          hash = :crypto.hash(:md5, url) |> Base.hex_encode32() |> to_string()
          path = Path.join(@path, hash)

          data =
            case File.stat(path) do
              {:ok, _} ->
                File.read!(path)

              _ ->
                r = Req.get!(url)

                if r.status == 200 do
                  File.write!(path, r.body)
                end

                r.body
            end
        end
      )
      |> Stream.flat_map(fn data ->
        case FeederEx.parse(data) do
          {:ok, rss, _rest} ->
            Enum.map(
              rss.entries,
              fn entry ->
                case entry do
                  %{enclosure: %{url: mp3_url}} ->
                    IO.puts("Fetching mp3 at: #{mp3_url}")

                    entry_hash = :crypto.hash(:md5, mp3_url) |> Base.hex_encode32() |> to_string()

                    path = Path.join(@path, entry_hash)

                    data =
                      case File.stat(path) do
                        {:ok, _} ->
                          File.read!(path)

                        _ ->
                          r = Req.get!(mp3_url)

                          if r.status == 200 do
                            File.write!(path, r.body)
                          end

                          r.body
                      end

                    {:ok, data}

                  _ ->
                    {:error, :no_mp3_url}
                end
              end
            )

          error ->
            Logger.error("Error parsing feed: #{inspect(error)}")
            {:error, error}
        end
      end)
      |> Stream.reject(fn result ->
        case result do
          {:error, _} -> true
          {:ok, _} -> false
        end
      end)
      |> Stream.map(fn {:ok, data} ->
        IO.puts("Parsing tag!")
        Id3vx.parse_binary!(data)
      end)
      |> Enum.to_list()

    IO.inspect(feeds)
    assert length(feeds) == 1
  end
end
