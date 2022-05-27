defmodule Id3vxTest do
  use ExUnit.Case
  # doctest Id3vx
  require Logger

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
      assert {:ok, tag} = Id3vx.parse_file(path)
      # IO.puts(path)
      # IO.inspect(tag)

      for frame <- tag.frames do
        if frame.data[:status] == :not_implemented do
          Logger.warn("Frame not implemented '#{frame.id}' in #{path}.")
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
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "Accidental Tech Podcast"},
                 id: "TALB",
                 label: "Album/Movie/Show title"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "Accidental Tech Podcast"},
                 id: "TPE1",
                 label: "Lead performer(s)/Soloist(s)"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "483: The Faceless Knob"},
                 id: "TIT2",
                 label: "Title/songname/content description"
               },
               %Id3vx.Frame{
                 data: %{
                   description: "",
                   encoding: :utf16,
                   language: "eng",
                   text: "Why run copper wires through your walls when you can run fiber?"
                 },
                 id: "COMM",
                 label: "Comments"
               },
               %Id3vx.Frame{
                 data: %{
                   status: :not_implemented
                 },
                 id: "USLT",
                 label: "Unsynchronised lyric/text transcription"
               },
               %Id3vx.Frame{
                 data: %{
                   status: :not_implemented
                 },
                 id: "CTOC",
                 label: nil
               },
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp0",
                   end_offset: 4_294_967_295,
                   end_time: 298_000,
                   frames: [
                     %Id3vx.Frame{
                       data: %{encoding: :utf16, text: "Recording?"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp1",
                   end_offset: 4_294_967_295,
                   end_time: 693_267,
                   frames: [
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp2",
                   end_offset: 4_294_967_295,
                   end_time: 1_120_306,
                   frames: [
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp3",
                   end_offset: 4_294_967_295,
                   end_time: 1_327_500,
                   frames: [
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp4",
                   end_offset: 4_294_967_295,
                   end_time: 1_721_941,
                   frames: [
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp5",
                   end_offset: 4_294_967_295,
                   end_time: 1_842_972,
                   frames: [
                     %Id3vx.Frame{
                       data: %{encoding: :utf16, text: "Sponsor: Linode"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp6",
                   end_offset: 4_294_967_295,
                   end_time: 1_963_500,
                   frames: [
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp7",
                   end_offset: 4_294_967_295,
                   end_time: 2_371_654,
                   frames: [
                     %Id3vx.Frame{
                       data: %{encoding: :utf16, text: "Fastmail vs. Legacy G Suite"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp8",
                   end_offset: 4_294_967_295,
                   end_time: 2_488_421,
                   frames: [
                     %Id3vx.Frame{
                       data: %{encoding: :utf16, text: "Sponsor: Trade Coffee"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp9",
                   end_offset: 4_294_967_295,
                   end_time: 2_929_500,
                   frames: [
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp10",
                   end_offset: 4_294_967_295,
                   end_time: 3_862_500,
                   frames: [
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp11",
                   end_offset: 4_294_967_295,
                   end_time: 4_851_575,
                   frames: [
                     %Id3vx.Frame{
                       data: %{
                         encoding: :utf16,
                         text: "Apple's new accessibility features"
                       },
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp12",
                   end_offset: 4_294_967_295,
                   end_time: 4_972_477,
                   frames: [
                     %Id3vx.Frame{
                       data: %{encoding: :utf16, text: "Sponsor: Squarespace (code ATP)"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp13",
                   end_offset: 4_294_967_295,
                   end_time: 5_446_455,
                   frames: [
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp14",
                   end_offset: 4_294_967_295,
                   end_time: 6_050_500,
                   frames: [
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp15",
                   end_offset: 4_294_967_295,
                   end_time: 6_498_350,
                   frames: [
                     %Id3vx.Frame{
                       data: %{
                         encoding: :utf16,
                         text: "#askatp: Remembering sign-in providers"
                       },
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp16",
                   end_offset: 4_294_967_295,
                   end_time: 6_560_500,
                   frames: [
                     %Id3vx.Frame{
                       data: %{encoding: :utf16, text: "Ending theme"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{
                   element_id: "chp17",
                   end_offset: 4_294_967_295,
                   end_time: 7_421_089,
                   frames: [
                     %Id3vx.Frame{
                       data: %{encoding: :utf16, text: "Casey's fiber trunk"},
                       id: "TIT2",
                       label: "Title/songname/content description"
                     },
                     %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{encoding: :iso8859_1, text: "7421089"},
                 id: "TLEN",
                 label: "Length"
               },
               %Id3vx.Frame{
                 data: %{encoding: :iso8859_1, text: "2022"},
                 id: "TYER",
                 label: nil
               },
               %Id3vx.Frame{
                 data: %{encoding: :iso8859_1, text: "Forecast"},
                 id: "TENC",
                 label: "Encoded by"
               },
               %Id3vx.Frame{
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
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "Maggie Tate"},
                 id: "TCOM"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "This video is about April 20"},
                 id: "TIT1"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "April 20"},
                 id: "TIT2"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "ProTranscoderTool (Apple MP3 v1"},
                 id: "TENC"
               },
               %Id3vx.Frame{
                 data: %{
                   description: "image",
                   mime_type: "image/jpg"
                 },
                 id: "APIC",
                 label: "Attached picture"
               },
               %Id3vx.Frame{
                 id: "PCST"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "Beam Radio"},
                 id: "TALB"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "Podcast"},
                 id: "TCON"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "2022 Lars Wikman"},
                 id: "TCOP"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "2022-05-05 14:00:00 UTC"},
                 id: "TDRL"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "http://www.beamrad.io/32"},
                 id: "TGID"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "Beam Radio 32: Untitled Episode"},
                 id: "TIT2"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "2022"},
                 id: "TYER"
               },
               %Id3vx.Frame{
                 id: "WFED"
               },
               %Id3vx.Frame{
                 data: %{url: "http://www.beamrad.io/32", description: "", encoding: :iso8859_1},
                 id: "WXXX"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "Lars Wikman"},
                 id: "TPE1"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "Lars Wikman"},
                 id: "TOPE"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "Lars Wikman"},
                 id: "TENC"
               },
               %Id3vx.Frame{
                 data: %{encoding: :utf16, text: "Lars Wikman"},
                 id: "TPUB"
               }
             ],
             revision: 0,
             size: 421_307,
             version: 3
           } = tag
  end
end
