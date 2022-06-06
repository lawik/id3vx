defmodule Id3vx.TagBuilderTest do
  use ExUnit.Case

  alias Id3vx.Frame
  alias Id3vx.Tag
  alias Id3vx.Frame.TableOfContents

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

  test "build basic tag v2.3 with some chapter frames" do
    tag =
      Tag.create(3)
      |> Tag.add_typical_chapter_and_toc(
        0,
        20,
        0,
        1024,
        "Chapter 1",
        fn chapter ->
          chapter
          |> Tag.add_text_frame("TPUB", "Chapter publisher")
          # Not a real picture
          |> Tag.add_attached_picture("", "image/jpeg", <<255, 0, 255>>)
        end
      )
      |> Tag.add_typical_chapter_and_toc(
        21,
        40,
        1025,
        2048,
        "Chapter 2",
        fn chapter ->
          chapter
          |> Tag.add_text_frame("TPUB", "Chapter publisher")
          |> Tag.add_attached_picture("", "image/jpeg", <<255, 0, 255>>)
        end
      )
      |> Tag.add_typical_chapter_and_toc(
        41,
        60,
        2049,
        3048,
        "Chapter 3",
        fn chapter ->
          chapter
          |> Tag.add_text_frame("TPUB", "Chapter publisher")
          |> Tag.add_attached_picture("", "image/jpeg", <<255, 0, 255>>)
        end
      )

    assert %Frame{
             id: "CTOC",
             data: %TableOfContents{
               element_id: "toc",
               child_elements: ["chp1", "chp2", "chp3"]
             }
           } = Tag.find_element(tag, "CTOC", "toc")

    # Check that it encodes and re-parses
    binary = Id3vx.encode_tag(tag)
    tag = Id3vx.parse_binary!(binary)

    assert %Tag{
             frames: [
               %Id3vx.Frame{
                 data: %Id3vx.Frame.TableOfContents{
                   child_elements: ["chp1", "chp2", "chp3"],
                   element_id: "toc",
                   frames: [],
                   ordered: true,
                   top_level: true
                 },
                 flags: %Id3vx.FrameFlags{
                   tag_alter_preservation: false,
                   file_alter_preservation: false,
                   read_only: false,
                   compression: false,
                   encryption: false,
                   grouping_identity: false
                 },
                 id: "CTOC"
               },
               %Id3vx.Frame{
                 data: %Id3vx.Frame.Chapter{
                   element_id: "chp1",
                   end_offset: 1024,
                   end_time: 20,
                   frames: [
                     %Id3vx.Frame{
                       data: %Id3vx.Frame.AttachedPicture{
                         description: "",
                         encoding: :utf16,
                         image_data: <<255, 0, 255>>,
                         mime_type: "image/jpeg",
                         picture_type: :other
                       },
                       id: "APIC",
                       label: "Attached picture"
                     },
                     %Id3vx.Frame{
                       data: %Id3vx.Frame.Text{
                         encoding: :utf16,
                         text: "Chapter publisher"
                       },
                       id: "TPUB",
                       label: "Publisher"
                     },
                     %Id3vx.Frame{
                       data: %Id3vx.Frame.Text{encoding: :utf16, text: "Chapter 1"},
                       id: "TIT2"
                     }
                   ],
                   start_offset: 0,
                   start_time: 0
                 },
                 id: "CHAP"
               },
               %Id3vx.Frame{
                 data: %Id3vx.Frame.Chapter{
                   element_id: "chp2",
                   end_offset: 2048,
                   end_time: 40,
                   frames: [
                     %Id3vx.Frame{
                       data: %Id3vx.Frame.AttachedPicture{
                         description: "",
                         encoding: :utf16,
                         image_data: <<255, 0, 255>>,
                         mime_type: "image/jpeg",
                         picture_type: :other
                       },
                       id: "APIC"
                     },
                     %Id3vx.Frame{
                       data: %Id3vx.Frame.Text{
                         encoding: :utf16,
                         text: "Chapter publisher"
                       },
                       id: "TPUB"
                     },
                     %Id3vx.Frame{
                       data: %Id3vx.Frame.Text{encoding: :utf16, text: "Chapter 2"},
                       id: "TIT2"
                     }
                   ],
                   start_offset: 1025,
                   start_time: 21
                 },
                 id: "CHAP"
               },
               %Id3vx.Frame{
                 data: %Id3vx.Frame.Chapter{
                   element_id: "chp3",
                   end_offset: 3048,
                   end_time: 60,
                   frames: [
                     %Id3vx.Frame{
                       data: %Id3vx.Frame.AttachedPicture{
                         description: "",
                         encoding: :utf16,
                         image_data: <<255, 0, 255>>,
                         mime_type: "image/jpeg",
                         picture_type: :other
                       },
                       id: "APIC"
                     },
                     %Id3vx.Frame{
                       data: %Id3vx.Frame.Text{
                         encoding: :utf16,
                         text: "Chapter publisher"
                       },
                       id: "TPUB"
                     },
                     %Id3vx.Frame{
                       data: %Id3vx.Frame.Text{encoding: :utf16, text: "Chapter 3"},
                       id: "TIT2"
                     }
                   ],
                   start_offset: 2049,
                   start_time: 41
                 },
                 id: "CHAP"
               }
             ],
             revision: 0,
             version: 3
           } = tag
  end

  test "v2.3 delete chapter frame" do
    tag =
      Tag.create(3)
      |> Tag.add_typical_chapter_and_toc(
        0,
        20,
        0,
        1024,
        "Chapter 1",
        fn chapter ->
          chapter
          |> Tag.add_text_frame("TPUB", "Chapter publisher")
          # Not a real picture
          |> Tag.add_attached_picture("", "image/jpeg", <<255, 0, 255>>)
        end
      )
      |> Tag.add_typical_chapter_and_toc(
        21,
        40,
        1025,
        2048,
        "Chapter 2",
        fn chapter ->
          chapter
          |> Tag.add_text_frame("TPUB", "Chapter publisher")
          |> Tag.add_attached_picture("", "image/jpeg", <<255, 0, 255>>)
        end
      )
      |> Tag.delete_chapter("chp1")

    assert length(tag.frames) == 2
    assert %{frames: [ctoc | _]} = tag
    assert length(ctoc.data.child_elements) == 1
  end
end
