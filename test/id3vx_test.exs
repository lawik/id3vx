defmodule Id3vxTest do
  use ExUnit.Case
  doctest Id3vx
  require Logger
  alias Id3vx.Tag
  alias Id3vx.Frame
  alias Id3vx.Frame.Unknown

  defp id3v2(path) do
    assert {output, 0} = System.cmd("id3v2", ["--list", path])
    output
  end

  defp ffmpeg(path) do
    {result, _} = System.shell("ffmpeg -hide_banner -i #{path} 2>&1")
    result
  end

  @samples_path "test/samples"
  setup_all do
    File.mkdir_p!(@samples_path)

    ok_files =
      "test/podcast-ok-samples.txt"
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(fn line ->
        with [filename, url] <- String.split(line, "|"),
             filepath <- Path.join(@samples_path, filename) do
          with {:error, :enoent} <- File.stat(filepath) do
            IO.puts("Downloading #{filename}...")
            {_, 0} = System.shell("curl -L '#{url}' > '#{filepath}'")
          end

          filepath
        else
          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, %{ok_files: ok_files}}
  end

  test "parse samples", %{ok_files: ok_files} do
    for path <- ok_files do
      binary = File.read!(path)
      assert {:ok, tag} = Id3vx.parse_binary(binary)

      for frame <- tag.frames do
        case frame.data do
          %Unknown{} ->
            Logger.warn("Frame not implemented '#{frame.id}' in #{path}.")

          _ ->
            nil
        end
      end
    end
  end

  test "atp483.mp3 parses ok" do
    assert {:ok, tag} = Id3vx.parse_file(Path.join(@samples_path, "atp483.mp3"))

    assert %Id3vx.Tag{
             extended_header: nil,
             flags: %Id3vx.TagFlags{
               experimental: false,
               extended_header: false,
               footer: nil,
               unsynchronisation: false
             },
             footer: nil,
             frames: [
               %Frame{
                 data: %{encoding: :utf16, text: "Accidental Tech Podcast"},
                 id: "TALB",
                 label: "Album/Movie/Show title"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "Accidental Tech Podcast"},
                 id: "TPE1",
                 label: "Lead performer(s)/Soloist(s)"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "483: The Faceless Knob"},
                 id: "TIT2",
                 label: "Title/songname/content description"
               },
               %Frame{
                 data: %{
                   content_description: "",
                   encoding: :utf16,
                   language: "eng",
                   content_text: "Why run copper wires through your walls when you can run fiber?"
                 },
                 id: "COMM",
                 label: "Comments"
               },
               %Frame{
                 data: %Unknown{},
                 id: "USLT",
                 label: "Unsynchronised lyric/text transcription"
               },
               %Frame{
                 data: %{
                   element_id: "toc",
                   frames: [],
                   ordered: true,
                   top_level: true,
                   child_elements: [
                     "chp0",
                     "chp1",
                     "chp2",
                     "chp3",
                     "chp4",
                     "chp5",
                     "chp6",
                     "chp7",
                     "chp8",
                     "chp9",
                     "chp10",
                     "chp11",
                     "chp12",
                     "chp13",
                     "chp14",
                     "chp15",
                     "chp16",
                     "chp17"
                   ]
                 },
                 id: "CTOC",
                 label: nil
               },
               %Frame{
                 data: %{
                   element_id: "chp0",
                   end_offset: 4_294_967_295,
                   end_time: 298_000,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "Recording?"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Frame{
                       data: %{
                         description: "",
                         encoding: :iso8859_1,
                         mime_type: "image/jpeg",
                         picture_type: :other
                       },
                       id: "APIC",
                       label: "Attached picture"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 0
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp1",
                   end_offset: 4_294_967_295,
                   end_time: 693_267,
                   frames: [
                     %Frame{
                       data: %{
                         encoding: :utf16,
                         text: "Follow-up: Mac-\"cleaning\" apps"
                       },
                       id: "TIT2",
                       label: "Title/songname/content description"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 298_000
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp2",
                   end_offset: 4_294_967_295,
                   end_time: 1_120_306,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "Casey's Ethernet project"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 693_267
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp3",
                   end_offset: 4_294_967_295,
                   end_time: 1_327_500,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "Home 5G"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 1_120_306
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp4",
                   end_offset: 4_294_967_295,
                   end_time: 1_721_941,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "IPv6"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 1_327_500
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp5",
                   end_offset: 4_294_967_295,
                   end_time: 1_842_972,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "Sponsor: Linode"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Frame{
                       data: %{
                         description: "chapter url",
                         encoding: :iso8859_1,
                         url: "https://linode.com/atp"
                       },
                       id: "WXXX",
                       label: "User defined URL link frame"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 1_721_941
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp6",
                   end_offset: 4_294_967_295,
                   end_time: 1_963_500,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "Follow-up: USB-C KVMs"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 1_842_972
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp7",
                   end_offset: 4_294_967_295,
                   end_time: 2_371_654,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "Fastmail vs. Legacy G Suite"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Frame{
                       data: %{
                         description: "chapter url",
                         encoding: :iso8859_1,
                         url: "https://www.caseyliss.com/fastmail"
                       },
                       id: "WXXX",
                       label: "User defined URL link frame"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 1_963_500
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp8",
                   end_offset: 4_294_967_295,
                   end_time: 2_488_421,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "Sponsor: Trade Coffee"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Frame{
                       data: %{
                         description: "chapter url",
                         encoding: :iso8859_1,
                         url: "https://www.drinktrade.com/atp"
                       },
                       id: "WXXX",
                       label: "User defined URL link frame"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 2_371_654
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp9",
                   end_offset: 4_294_967_295,
                   end_time: 2_929_500,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "Fitness+ PR tour"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 2_488_421
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp10",
                   end_offset: 4_294_967_295,
                   end_time: 3_862_500,
                   frames: [
                     %Frame{
                       data: %{
                         encoding: :utf16,
                         text: "Rivian: physical vs. touch controls"
                       },
                       id: "TIT2",
                       label: "Title/songname/content description"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 2_929_500
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp11",
                   end_offset: 4_294_967_295,
                   end_time: 4_851_575,
                   frames: [
                     %Frame{
                       data: %{
                         encoding: :utf16,
                         text: "Apple's new accessibility features"
                       },
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Frame{
                       data: %{
                         description: "chapter url",
                         encoding: :iso8859_1,
                         url:
                           "https://www.apple.com/newsroom/2022/05/apple-previews-innovative-accessibility-features/"
                       },
                       id: "WXXX",
                       label: "User defined URL link frame"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 3_862_500
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp12",
                   end_offset: 4_294_967_295,
                   end_time: 4_972_477,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "Sponsor: Squarespace (code ATP)"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Frame{
                       data: %{
                         description: "chapter url",
                         encoding: :iso8859_1,
                         url: "https://squarespace.com/atp"
                       },
                       id: "WXXX",
                       label: "User defined URL link frame"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 4_851_575
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp13",
                   end_offset: 4_294_967_295,
                   end_time: 5_446_455,
                   frames: [
                     %Frame{
                       data: %{
                         encoding: :utf16,
                         text: "#askatp: Music app for concert albums"
                       },
                       id: "TIT2",
                       label: "Title/songname/content description"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 4_972_477
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp14",
                   end_offset: 4_294_967_295,
                   end_time: 6_050_500,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "#askatp: Safari extensions"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 5_446_455
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp15",
                   end_offset: 4_294_967_295,
                   end_time: 6_498_350,
                   frames: [
                     %Frame{
                       data: %{
                         encoding: :utf16,
                         text: "#askatp: Remembering sign-in providers"
                       },
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Frame{
                       data: %{
                         description: "chapter url",
                         encoding: :iso8859_1,
                         url: "https://twitter.com/_brianhamilton/status/1523715834170036225"
                       },
                       id: "WXXX",
                       label: "User defined URL link frame"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 6_050_500
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp16",
                   end_offset: 4_294_967_295,
                   end_time: 6_560_500,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "Ending theme"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Frame{
                       data: %{
                         description: "chapter url",
                         encoding: :iso8859_1,
                         url: "https://www.jonathanmann.net/"
                       },
                       id: "WXXX",
                       label: "User defined URL link frame"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 6_498_350
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{
                   element_id: "chp17",
                   end_offset: 4_294_967_295,
                   end_time: 7_421_089,
                   frames: [
                     %Frame{
                       data: %{encoding: :utf16, text: "Casey's fiber trunk"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Frame{
                       data: %{
                         description: "",
                         encoding: :iso8859_1,
                         mime_type: "image/png",
                         picture_type: :other
                       },
                       id: "APIC",
                       label: "Attached picture"
                     }
                   ],
                   start_offset: 4_294_967_295,
                   start_time: 6_560_500
                 },
                 id: "CHAP",
                 label: "Chapters"
               },
               %Frame{
                 data: %{encoding: :iso8859_1, text: "7421089"},
                 id: "TLEN",
                 label: "Length"
               },
               %Frame{
                 data: %{encoding: :iso8859_1, text: "2022"},
                 id: "TYER",
                 label: nil
               },
               %Frame{
                 data: %{encoding: :iso8859_1, text: "Forecast"},
                 id: "TENC",
                 label: "Encoded by"
               },
               %Frame{
                 data: %{
                   description: "",
                   encoding: :iso8859_1,
                   mime_type: "image/png",
                   picture_type: :cover
                 },
                 id: "APIC",
                 label: "Attached picture"
               }
             ],
             revision: 0,
             size: 428_980,
             version: 3
           } = tag
  end

  test "beamradio32.mp3 parses ok" do
    assert {:ok, tag} = Id3vx.parse_file(Path.join(@samples_path, "beamradio32.mp3"))

    assert %Id3vx.Tag{
             flags: %Id3vx.TagFlags{
               extended_header: false,
               unsynchronisation: false
             },
             frames: [
               %Frame{
                 data: %{encoding: :utf16, text: "Maggie Tate"},
                 id: "TCOM"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "This video is about April 20"},
                 id: "TIT1"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "April 20"},
                 id: "TIT2"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "ProTranscoderTool (Apple MP3 v1"},
                 id: "TENC"
               },
               %Frame{
                 data: %{
                   description: "image",
                   mime_type: "image/jpg"
                 },
                 id: "APIC",
                 label: "Attached picture"
               },
               %Frame{
                 id: "PCST"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "Beam Radio"},
                 id: "TALB"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "Podcast"},
                 id: "TCON"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "2022 Lars Wikman"},
                 id: "TCOP"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "2022-05-05 14:00:00 UTC"},
                 id: "TDRL"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "http://www.beamrad.io/32"},
                 id: "TGID"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "Beam Radio 32: Untitled Episode"},
                 id: "TIT2"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "2022"},
                 id: "TYER"
               },
               %Frame{
                 data: %{url: "https://www.beamrad.io/rss"},
                 id: "WFED"
               },
               %Frame{
                 data: %{url: "http://www.beamrad.io/32", description: "", encoding: :iso8859_1},
                 id: "WXXX"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "Lars Wikman"},
                 id: "TPE1"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "Lars Wikman"},
                 id: "TOPE"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "Lars Wikman"},
                 id: "TENC"
               },
               %Frame{
                 data: %{encoding: :utf16, text: "Lars Wikman"},
                 id: "TPUB"
               }
             ],
             revision: 0,
             size: 421_307,
             version: 3
           } = tag
  end

  test "ATP chapter encodes ok" do
    inpath = Path.join(@samples_path, "atp483.mp3")
    assert {:ok, tag} = Id3vx.parse_file(inpath)
    outpath = Path.join(@samples_path, "atp-re-encode.mp3")
    assert Id3vx.replace_tag!(tag, inpath, outpath)
    assert id3v2(outpath) =~ "CHAP"
    assert ffmpeg(outpath) =~ "CHAP"
  end

  test "Replace tag in mp3 file" do
    path = Path.join(@samples_path, "beamradio32.mp3")
    outpath = "/tmp/out-beam.mp3"
    assert {:ok, tag} = Id3vx.parse_file(path)
    original_tag_size = tag.size + 10

    tag = %Tag{
      version: 3,
      revision: 0,
      frames: [
        %Frame{
          data: %{encoding: :utf16, text: "New tag"},
          id: "TIT1"
        }
      ]
    }

    assert :ok = Id3vx.replace_tag(tag, path, outpath)

    # Check that the files still parse
    assert {:ok, in_tag} = Id3vx.parse_file(path)
    assert 19 = Enum.count(in_tag.frames)
    assert {:ok, out_tag} = Id3vx.parse_file(outpath)
    new_tag_size = out_tag.size + 10

    # Figure out size difference
    size_diff = original_tag_size - new_tag_size

    assert 1 = Enum.count(out_tag.frames)
    assert {:ok, in_stat} = File.stat(path)
    assert {:ok, out_stat} = File.stat(outpath)

    # Confirm size difference
    assert in_stat.size - size_diff == out_stat.size
  end

  test "Add tag to mp3 file" do
    path = Path.join(@samples_path, "test.mp3")
    File.write(path, "pretend this is MPEG")
    outpath = "/tmp/out.mp3"
    assert {:error, %{context: :parse_prepend_tag}} = Id3vx.parse_file(path)

    tag = %Tag{
      version: 3,
      revision: 0,
      frames: [
        %Frame{
          data: %{encoding: :utf16, text: "New tag"},
          id: "TIT1"
        }
      ]
    }

    assert :ok = Id3vx.replace_tag(tag, path, outpath)

    # Check that the files still parse
    assert {:error, %{context: :parse_prepend_tag}} = Id3vx.parse_file(path)
    assert {:ok, out_tag} = Id3vx.parse_file(outpath)

    assert 1 = Enum.count(out_tag.frames)
  end

  test "Replace tag to mp3 file with ID3v2.2" do
    path = Path.join(@samples_path, "test.mp3")
    media = "pretend this is MPEG"
    # tag should be 7 bytes in size for the word "filling"
    tag = <<"ID3", 2::integer, 0::integer, 0::size(8), 7::size(32), "filling">>

    File.write(path, tag <> media)
    outpath = "/tmp/out.mp3"
    assert {:error, %{context: :unsupported_tag}} = Id3vx.parse_file(path)

    tag = %Tag{
      version: 3,
      revision: 0,
      frames: [
        %Frame{
          data: %{encoding: :utf16, text: "New tag"},
          id: "TIT1"
        }
      ]
    }

    assert :ok = Id3vx.replace_tag(tag, path, outpath)

    # Check that the files still parse
    assert {:error, %{context: :unsupported_tag}} = Id3vx.parse_file(path)
    assert {:ok, out_tag} = Id3vx.parse_file(outpath)

    assert 1 = Enum.count(out_tag.frames)
  end

  test "Replace tag to mp3 file with ID3v2.4" do
    path = Path.join(@samples_path, "test.mp3")
    media = "pretend this is MPEG"
    # tag should be 7 bytes in size for the word "filling"
    tag = <<"ID3", 4::integer, 0::integer, 0::size(8), 7::size(32), "filling">>

    File.write(path, tag <> media)
    outpath = "/tmp/out.mp3"
    assert {:error, %{context: :unsupported_tag}} = Id3vx.parse_file(path)

    tag = %Tag{
      version: 3,
      revision: 0,
      frames: [
        %Frame{
          data: %{encoding: :utf16, text: "New tag"},
          id: "TIT1"
        }
      ]
    }

    assert :ok = Id3vx.replace_tag(tag, path, outpath)

    # Check that the files still parse
    assert {:error, %{context: :unsupported_tag}} = Id3vx.parse_file(path)
    assert {:ok, out_tag} = Id3vx.parse_file(outpath)

    assert 1 = Enum.count(out_tag.frames)
  end

  test "ffmpeg parses attached picture" do
    path = Path.join(@samples_path, "atp483.mp3")
    outpath = "/tmp/out-atp483.mp3"

    # Before:
    {result, _} = System.shell("ffmpeg -i #{path} 2>&1")
    refute String.contains?(result, "Error decoding attached picture description")

    image = File.read!("test/samples/sample.png")
    new_tag = Id3vx.Tag.create(3)
    new_tag = Id3vx.Tag.add_text_frame(new_tag, "TIT2", "Cool Title")
    new_tag = Id3vx.Tag.add_attached_picture(new_tag, "", "image/png", image)
    Id3vx.replace_tag(new_tag, path, outpath)

    {:ok, tag} = Id3vx.parse_file(outpath)

    # After:
    {result, _} = System.shell("ffmpeg -i #{outpath} 2>&1")
    refute String.contains?(result, "Error decoding attached picture description")
  end

  test "ffmpeg parses title bom" do
    path = Path.join(@samples_path, "atp483.mp3")
    outpath = "/tmp/bomfunk.mp3"

    image = File.read!("test/samples/sample.png")

    new_tag = Id3vx.Tag.create(3)
    # new_tag = Id3vx.Tag.add_text_frame(new_tag, "TIT2", "Cool Title")
    new_tag = Id3vx.Tag.add_attached_picture(new_tag, "foo", "image/png", image)
    Id3vx.replace_tag!(new_tag, path, outpath)

    {result, _} = System.shell("ffmpeg -i #{outpath} 2>&1")
    refute String.contains?(result, "Incorrect BOM")
  end
end
