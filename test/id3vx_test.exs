defmodule Id3vxTest do
  use ExUnit.Case
  #doctest Id3vx


  @sample_path "test/samples"
  test "parse samples" do
    samples =
      @sample_path
      |> File.ls!()
      |> Enum.filter(fn name ->
        name =~ ".id3"
      end)

    for sample <- samples do
      IO.puts(sample)
      assert {:ok, parsed} = Id3vx.parse_stream(Path.join("test/samples", sample))
      IO.inspect(parsed)
    end
  end
end
