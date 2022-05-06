defmodule Id3vxTest do
  use ExUnit.Case
  # doctest Id3vx

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
        end)

      results =
        for sample <- samples do
          path = Path.join(Path.expand(sample_path), sample)
          IO.puts(sample)

          result = assert {:ok, _} = result = Id3vx.parse_stream(path)

          {path, result}
        end
    end
  end
end
