defmodule Id3vx.CompatibilityTest do
  use ExUnit.Case, async: false

  defp list(path) do
    assert {output, 0} = System.cmd("id3v2", ["--list", path])
    output
  end

  @tag :require_id3v2
  test "bug attaching picture nukes the text frames" do
    assert "test/samples/test.mp3: No ID3 tag\n" ==
             list("test/samples/test.mp3")

    image = File.read!("test/samples/sample.png")
    tag = Id3vx.Tag.create(3)
    tag = Id3vx.Tag.add_text_frame(tag, "TIT2", "Cool Title")
    tag = Id3vx.Tag.add_attached_picture(tag, "", "image/png", image)
    # tag = Id3vx.Tag.add_custom_url(tag, "foobarbaz descript", "https://example.com")
    Id3vx.replace_tag(tag, "test/samples/test.mp3", "test/samples/tagged.mp3")
    t = Id3vx.parse_file!("test/samples/tagged.mp3")
    assert %{frames: [_tit2, _apic]} = t

    assert list("test/samples/tagged.mp3") =~ "APIC"
    assert list("test/samples/tagged.mp3") =~ "TIT2"
  end

  @tag :require_id3v2
  test "bug attaching picture nukes the text frames, reverse order" do
    assert "test/samples/test.mp3: No ID3 tag\n" ==
             list("test/samples/test.mp3")

    image = File.read!("test/samples/sample.png")
    tag = Id3vx.Tag.create(3)
    tag = Id3vx.Tag.add_attached_picture(tag, "foo", "image/png", image)
    tag = Id3vx.Tag.add_text_frame(tag, "TIT2", "Cool Title")
    # tag = Id3vx.Tag.add_custom_url(tag, "foobarbaz descript", "https://example.com")
    Id3vx.replace_tag(tag, "test/samples/test.mp3", "test/samples/tagged.mp3")

    assert list("test/samples/tagged.mp3") =~ "APIC"
    assert list("test/samples/tagged.mp3") =~ "TIT2"
  end

  @tag :require_id3v2
  test "bug attaching picture nukes the text frames, but not on empty image" do
    assert "test/samples/test.mp3: No ID3 tag\n" ==
             list("test/samples/test.mp3")

    File.write!("test/samples/empty.png", <<0xFF, 0xFF, 0xFF>>)
    image = File.read!("test/samples/empty.png")
    tag = Id3vx.Tag.create(3)
    tag = Id3vx.Tag.add_text_frame(tag, "TIT2", "Cool Title")
    tag = Id3vx.Tag.add_attached_picture(tag, "", "image/png", image)
    # tag = Id3vx.Tag.add_custom_url(tag, "foobarbaz descript", "https://example.com")
    Id3vx.replace_tag(tag, "test/samples/test.mp3", "test/samples/tagged.mp3")

    assert list("test/samples/tagged.mp3") =~ "APIC"
    assert list("test/samples/tagged.mp3") =~ "TIT2"
  end
end
