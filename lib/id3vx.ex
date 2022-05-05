defmodule Id3vx do
  @moduledoc """
  Documentation for `Id3vx`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Id3vx.hello()
      :world

  """
  defmodule Tag do
    defstruct version: nil, flags: nil, size: nil, extended_header: nil, footer: nil, frames: nil
  end

  defmodule TagFlags do
    defstruct unsynchronized: nil, extended_header: nil, experimental: nil, footer: nil
  end

  alias Id3vx.Tag
  alias Id3vx.TagFlags

  @parse_states [
    :parse_prepend_tag,
    :seek_tag,
    :parse_extended_header,
    :parse_extended_header_flags,
    :skip_padding,
    :fetch_frames,
    :decode_tag_unsynchronisation,
    :parse_frames,
    :parse_footer,
    :parse_append_tag,
    :done
  ]

  # parse tag header, get flags
  # handle flags:
  #   if extended headerparse extended header
  #

  def parse_stream(path) do
    stream = File.stream!(path, [:raw], 2048)
    {<<>>,<<>>,stream}
    |> parse
  end

  def parse_binary(<<binary>>) do
    {<<>>,binary}
    |> parse
  end

  def get_bytes({used, unused, %File.Stream{} = stream}, bytes) do
    left = byte_size(unused)
    {taken, remainder} =
      case bytes - left do
        take when take > 0 ->
          [<< data :: binary-size(take), rest::binary>>] = Enum.take(stream, 1)
          {unused <> data, rest}
        take when take == 0 ->
          [<<rest>>] = Enum.take(stream, 1)
          {<<unused>>, rest}

        take when take < 0 ->
          << data :: binary-size(bytes), rest::binary>> = unused
          {{ data, rest }}
      end
    {taken, {used <> taken, remainder, stream}}
  end

  def get_bytes({used, unused}, bytes) do
    << data :: binary-size(bytes), rest::binary>> = unused
    { data, { used <> data, rest }}
  end

  def parse(source) do
    iterate(source, :parse_prepend_tag, nil)
  end

  def iterate(source, step, state) do
    case parse_step(source, step, state) do
      {:done, result} -> result
      {next_step, source, state} -> iterate(source, next_step, state)
    end
  end

  defp parse_step(source, :parse_prepend_tag, _) do
    {data, source} = get_bytes(source, 10)
    case parse_tag(data) do
      {:ok, tag} ->
        if tag.flags.extended_header do
          {:parse_extended_header, source, tag}
        else
          {:skip_padding, source, tag}
        end
      :not_found ->
        {:done, {:error, :not_found}}
    end
  end

  defp parse_step(source, :parse_extended_header, tag) do
    {data, source} = get_bytes(source, 6)
    #parse_extended_header(data)
    {:done, {:error, :notimplemented}}
  end

  defp parse_step(source, step, state) do
    IO.puts("Step not implemented #{step}")
    {:done, {:ok, state}}
  end

  def parse_tag(<< "ID3", major :: integer, minor :: integer, unsynchronized :: size(1), extended_header :: size(1), experimental :: size(1), footer :: size(1), _unused :: size(4), tag_size :: binary-size(4)>>) do
    flags = %TagFlags{
      unsynchronized: unsynchronized == 1,
      extended_header: extended_header == 1,
      experimental: experimental == 1,
      footer: footer == 1
    }
    {:ok, %{version: {major, minor}, flags: flags, size: tag_size}}
  end

  def parse_tag(bin) do
    :not_found
  end
end
