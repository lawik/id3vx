defmodule Id3vx do
  @moduledoc """
  Provides the API for interacting with ID3 tags and files that
  contain them.

  ## Examples

  ### Parse from file

      iex> {:ok, tag} = Id3vx.parse_file("test/samples/beamradio32.mp3")
      ...> tag.version
      3

  ### Encode new tag

      iex> Id3vx.Tag.create(3) |> Id3vx.Tag.add_text_frame("TIT1", "Title!") |> Id3vx.encode_tag()
      <<73, 68, 51, 3, 0, 0, 0, 0, 0, 27, 84, 73, 84, 49, 0, 0, 0, 17, 0, 0, 1, 254, 255, 0, 84, 0, 105, 0, 116, 0, 108, 0, 101, 0, 33, 0, 0>>

  ### Parse from binary

      iex> tag = Id3vx.Tag.create(3) |> Id3vx.Tag.add_text_frame("TIT1", "Title!")
      ...> tag_binary = Id3vx.encode_tag(tag)
      ...> {:ok, tag} = Id3vx.parse_binary(tag_binary)
      ...> tag.version
      3

  """

  require Logger

  alias Id3vx.Tag
  alias Id3vx.TagFlags
  alias Id3vx.ExtendedHeaderV4
  alias Id3vx.ExtendedHeaderV3
  alias Id3vx.ExtendedHeaderFlags
  alias Id3vx.Error
  alias Id3vx.Frame
  alias Id3vx.Utils

  @parse_states [
    :parse_prepend_tag,
    :seek_tag,
    :parse_extended_header,
    :parse_extended_header_flags,
    :parse_frames,
    :skip_padding,
    :parse_footer,
    :parse_append_tag,
    :done
  ]

  @doc false
  def parse_states, do: @parse_states

  @doc """
  Parse an ID3 tag from the given file path.

  It will open the file read-only and only read as many bytes as
  necessary.

  Returns an `Id3vx.Tag` struct or throws an `Id3vx.Error`.
  """
  @spec parse_file!(path :: String.t()) :: Tag.t()
  def parse_file!(path) do
    try do
      case File.open(path, [:read, :binary]) do
        {:ok, device} ->
          parse_io(device)

        {:error, e} ->
          throw(%Error{
            message: "Could not load file '#{inspect(path)}', error: #{inspect(e)}",
            context: {:file_open, e}
          })
      end
    catch
      e -> raise e
    end
  end

  @doc """
  Parse an ID3 tag from the given file path.

  It will open the file read-only and only read as many bytes as
  necessary.

  Returns `{:ok, Id3vx.Tag}` struct or throws an `{:error, Id3vx.Error}`.
  """
  @spec parse_file(path :: String.t()) :: {:ok, Tag.t()} | {:error, %Error{}}
  def parse_file(path) do
    try do
      {:ok, parse_file!(path)}
    catch
      e -> {:error, e}
    end
  end

  @doc """
  Parse an ID3 tag from a binary.

  Returns an `Id3vx.Tag` struct or throws an `Id3vx.Error`.
  """
  def parse_binary!(<<binary::binary>>) do
    try do
      parse({<<>>, binary})
    catch
      e -> raise e
    end
  end

  @doc """
  Parse an ID3 tag from a binary.

  Returns `{:ok, Id3vx.Tag}` struct or throws an `{:error, Id3vx.Error}`.
  """
  def parse_binary(binary) do
    try do
      {:ok, parse_binary!(binary)}
    catch
      e -> {:error, e}
    end
  end

  @doc """
  Replace an existing ID3 tag in a file with the provided tag producing a new output file.

  Returns `:ok` or `{:error, Id3vx.Error}`.
  """
  def replace_tag(%Tag{} = tag, infile_path, outfile_path) do
    try do
      replace_tag!(tag, infile_path, outfile_path)
    catch
      e -> {:error, e}
    end
  end

  @doc """
  Replace an existing ID3 tag in a file with the provided tag producing a new output file.

  Returns `:ok` or throws an `Id3vx.Error`.
  """
  def replace_tag!(%Tag{} = tag, infile_path, outfile_path) do
    binary = encode_tag(tag)
    {:ok, indevice} = File.open(infile_path, [:read, :binary])
    {:ok, outdevice} = File.open(outfile_path, [:write, :binary])
    tag_header = IO.binread(indevice, 10)
    {:ok, tag} = parse_tag(tag_header)
    _skip = IO.binread(indevice, tag.size)
    IO.binwrite(outdevice, binary)
    read_write(indevice, outdevice)
  end

  defp parse_io(device) do
    parse(device)
  end

  # 1 Mb
  @chunk_size 1024 * 1024
  defp read_write(indevice, outdevice) do
    case IO.binread(indevice, @chunk_size) do
      :eof ->
        :ok

      data ->
        IO.binwrite(outdevice, data)
        read_write(indevice, outdevice)
    end
  end

  @doc """
  Find and returns the tag binary without parsing it.

  Mostly used in tests.
  """
  def get_tag_binary(<<binary::binary>>) do
    <<header::binary-size(10), rest::binary>> = binary
    {:ok, tag} = parse_tag(header)
    tag_size = tag.size
    <<body::binary-size(tag_size), _::binary>> = rest
    header <> body
  end

  @doc """
  Generate a tag binary from a provided `Id3vx.Tag` struct.

  Returns a binary.
  """
  @spec encode_tag(tag :: Tag.t()) :: binary()
  def encode_tag(%Tag{version: 3} = tag) do
    frames = encode_frames(tag)

    {frames, desynched?, _padded?} = Utils.unsynchronise_if_needed(frames)

    tag_flags =
      if is_nil(tag.flags) do
        TagFlags.all_false()
      else
        tag.flags
      end

    tag = %{tag | flags: %{tag_flags | unsynchronisation: desynched?}}
    flags = TagFlags.as_binary(tag.flags, tag)

    tag_size =
      frames
      |> byte_size()
      |> Utils.encode_synchsafe_integer()

    IO.iodata_to_binary([
      "ID3",
      <<tag.version>>,
      <<tag.revision>>,
      flags,
      tag_size,
      frames
    ])
  end

  @doc false
  def encode_frames(%Tag{frames: []}) do
    throw(%Error{message: "Cannot generate an empty ID3 tag"})
  end

  @doc false
  def encode_frames(%Tag{frames: frames} = tag) do
    Enum.reduce(frames, <<>>, fn frame, acc ->
      try do
        acc <> Frame.encode_frame(frame, tag)
      catch
        :discard_frame -> acc
      end
    end)
  end

  defp get_bytes(device, bytes) when is_pid(device) do
    data = IO.binread(device, bytes)
    {data, device}
  end

  defp get_bytes({used, unused}, bytes) do
    <<data::binary-size(bytes), rest::binary>> = unused
    {data, {used <> data, rest}}
  end

  defp parse(source) do
    iterate(source, :parse_prepend_tag, nil)
  end

  defp iterate(source, step, state) do
    case parse_step(source, step, state) do
      {:done, result} -> result
      {next_step, source, state} -> iterate(source, next_step, state)
    end
  end

  defp parse_step(source, :parse_prepend_tag, _) do
    {data, source} = get_bytes(source, 10)

    case parse_tag(data) do
      {:ok, tag} ->
        {:parse_frames, source, tag}

      :not_found ->
        throw(%Error{message: "Tag not found", context: :parse_prepend_tag})
    end
  end

  defp parse_step(source, :parse_extended_header, tag) do
    {:parse_frames, source, tag}
  end

  defp parse_step(source, :parse_frames, %{version: 4} = tag) do
    frames_size =
      tag.size
      |> subtract_extended_header(tag)
      |> subtract_footer(tag)

    {data, source} = get_bytes(source, frames_size)

    data =
      if tag.flags.unsynchronisation do
        Utils.decode_unsynchronized(data)
      else
        data
      end

    {tag, data} =
      if tag.flags.extended_header do
        <<ext_header_size::size(32), data::binary>> = data
        full_ext_header_size = ext_header_size + 4
        <<ext_data::binary-size(full_ext_header_size), data::binary>> = data
        ext_header = parse_extended_header_fixed(tag, ext_data)
        {%{tag | extended_header: ext_header}, data}
      else
        {tag, data}
      end

    frames = Frame.parse_frames(tag, data)
    tag = %{tag | frames: frames}

    if tag.flags.footer do
      {:parse_footer, source, tag}
    else
      {:skip_padding, source, tag}
    end
  end

  defp parse_step(source, :parse_frames, %{version: 3} = tag) do
    frames_size =
      tag.size
      |> subtract_extended_header(tag)
      |> subtract_footer(tag)

    {data, _source} = get_bytes(source, frames_size)

    data =
      if tag.flags.unsynchronisation do
        Utils.decode_unsynchronized(data)
      else
        data
      end

    frames = Frame.parse_frames(tag, data, [])
    tag = %{tag | frames: frames}

    {:done, tag}
  end

  defp parse_step(_source, step, state) do
    Logger.warn("Step not implemented #{step}")
    {:done, state}
  end

  defp parse_tag(
         <<"ID3", 4::integer, minor::integer, unsynchronisation::size(1),
           extended_header::size(1), experimental::size(1), footer::size(1), _unused::size(4),
           tag_size::binary-size(4)>>
       ) do
    if true do
      throw(%Error{message: "ID3v2.4 is not currently supported. Contributions are welcome."})
    else
      # Started implementation of version: 4
      flags = %TagFlags{
        unsynchronisation: unsynchronisation == 1,
        extended_header: extended_header == 1,
        experimental: experimental == 1,
        footer: footer == 1
      }

      tag_size = Utils.decode_synchsafe_integer(tag_size)

      {:ok, %Tag{version: 4, revision: minor, flags: flags, size: tag_size}}
    end
  end

  defp parse_tag(
         <<"ID3", 3::integer, minor::integer, flag_bytes::size(8), tag_size::binary-size(4)>>
       ) do
    <<unsynchronisation::size(1), extended_header::size(1), experimental::size(1),
      _unused::size(5)>> = <<flag_bytes>>

    flags = %TagFlags{
      unsynchronisation: unsynchronisation == 1,
      extended_header: extended_header == 1,
      experimental: experimental == 1
    }

    tag_size = Utils.decode_synchsafe_integer(tag_size)

    {:ok, %Tag{version: 3, revision: minor, flags: flags, size: tag_size}}
  end

  defp parse_tag(_bin) do
    :not_found
  end

  defp parse_extended_header_fixed(
         %{version: 4},
         <<size::binary-size(4), _::binary-size(1), _::size(1), is_update::size(1),
           crc_data_present::size(1), tag_restrictions::size(1), _unused::size(4)>>
       ) do
    %ExtendedHeaderV4{
      size: Utils.decode_synchsafe_integer(size),
      flag_bytes: 0x01,
      flags: %ExtendedHeaderFlags{
        is_update: is_update == 1,
        crc_data_present: crc_data_present == 1,
        tag_restrictions: tag_restrictions == 1
      }
    }
  end

  defp parse_extended_header_fixed(
         %{version: 3},
         <<size::binary-size(4), crc_data_present::1, _::15, rest::binary>>
       ) do
    {crc_data, padding_size} =
      case rest do
        <<padding_size::size(32)>> -> {nil, padding_size}
        <<padding_size::size(32), crc_data::binary-size(4)>> -> {crc_data, padding_size}
      end

    %ExtendedHeaderV3{
      size: size,
      flags: %ExtendedHeaderFlags{
        crc_data_present: crc_data_present == 1
      },
      crc_data: crc_data,
      padding_size: padding_size
    }
  end

  defp subtract_extended_header(size, %{
         flags: %{extended_header: true},
         extended_header: %{size: ex_size}
       }) do
    size - ex_size
  end

  defp subtract_extended_header(size, _) do
    size
  end

  defp subtract_footer(size, %{flags: %{footer: true}}) do
    size - 10
  end

  defp subtract_footer(size, _) do
    size
  end
end
