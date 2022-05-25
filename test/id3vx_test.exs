defmodule Id3vxTest do
  use ExUnit.Case
  # doctest Id3vx

  # @errors ["MusicBrainz.XSOP-frame", "24.itunes.astronomycast-conversion", "24.itunes"]
  @errors []
  @not_ready []
  @ok_extensions [
    ".id3",
    ".mp3"
  ]

  @sample_paths ["test/samples"]
  test "parse samples" do
    for sample_path <- @sample_paths do
      samples =
        sample_path
        |> Path.expand()
        |> File.ls!()
        |> Enum.filter(fn name ->
          Enum.any?(@ok_extensions, fn e ->
            name =~ e
          end)
          and (
            String.starts_with?(name, "beam") or
            String.starts_with?(name, "kodsnack") or
            String.starts_with?(name, "atp")
          )
        end)
        |> Enum.reject(fn name ->
          Enum.any?(@errors, fn err ->
            name =~ err
          end)
        end)

      results =
        for {sample, index} <- Enum.with_index(samples) do
          path = Path.join(Path.expand(sample_path), sample)
          IO.puts(index + 1)
          IO.puts(sample)

          assert {:ok, tag1} = result = Id3vx.parse_file(path)
          IO.inspect(Id3vx.get_tag_binary(File.read!(path)))
          #assert {:ok, tag2} = result = Id3vx.parse_stream(path)
          #assert length(tag1.frames) == length(tag2.frames)
          tag = tag1

          ts = IO.inspect(tag.size, label: "tag size")
          fs = Enum.map(tag.frames, fn frame ->
            frame.size + 10
          end)
          |> Enum.sum()
          |> IO.inspect(label: "sum frame sizes")

          (ts - fs) |> IO.inspect(label: "tag minus frame")


          for frame <- tag.frames do
            IO.puts(frame.id)
          end

          {path, result}
        end
    end
  end
end
