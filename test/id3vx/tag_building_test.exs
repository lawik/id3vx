defmodule Id3vx.TagBuilderTest do
  use ExUnit.Case

  alias Id3vx.Tag

  test "build basic tag v2.3 with some text frames" do
    tag =
      Tag.create(3)
      |> Tag.add_text_frame("TIT1", "Regular Programming")
      |> Tag.add_text_frame("TIT2", "Underjord")
      |> Tag.add_text_frame("TIT3", "About Washing Machines")
      |> Tag.add_text_frame("TPE3", "Lars Wikman")
      |> Tag.add_text_frame("TPUB", "Lars Wikman")

    assert %{frames: frames} = tag
    assert Enum.count(frames) == 5

    assert binary = Id3vx.encode_tag(tag)
    assert {:ok, %Tag{version: 3, revision: 0} = parsed} = Id3vx.parse_binary(binary)

    Enum.zip(parsed.frames, tag.frames)
    |> Enum.each(fn {f1, f2} ->
      assert [f1.data.text] == f2.data.text
    end)
  end
end
