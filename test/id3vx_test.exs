defmodule Id3vxTest do
  use ExUnit.Case
  # doctest Id3vx

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
      assert {:ok, tag} = result = Id3vx.parse_file(path)
      IO.inspect(tag)
    end
  end

  test "beamradio32.mp3 parses ok" do
    assert {:ok, tag} = result = Id3vx.parse_file(Path.join(@samples_path, "beamradio32.mp3"))

    assert %Id3vx.Tag{
             flags: %Id3vx.TagFlags{
               extended_header: false,
               unsynchronized: false
             },
             frames: [
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["Maggie Tate"]},
                 id: "TCOM"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["This video is about April 20"]},
                 id: "TIT1"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["April 20"]},
                 id: "TIT2"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["ProTranscoderTool (Apple MP3 v1"]},
                 id: "TENC"
               },
               %Id3vx.Frame{
                 data: %{
                   description: "image",
                   mime_type: "image/jpg"
                 },
                 id: "APIC"
               },
               %Id3vx.Frame{
                 id: "PCST"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["Beam Radio"]},
                 id: "TALB"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["Podcast"]},
                 id: "TCON"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["2022 Lars Wikman"]},
                 id: "TCOP"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["2022-05-05 14:00:00 UTC"]},
                 id: "TDRL"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["http://www.beamrad.io/32"]},
                 id: "TGID"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["Beam Radio 32: Untitled Episode"]},
                 id: "TIT2"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["2022"]},
                 id: "TYER"
               },
               %Id3vx.Frame{
                 id: "WFED"
               },
               %Id3vx.Frame{
                 id: "WXXX"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["Lars Wikman"]},
                 id: "TPE1"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["Lars Wikman"]},
                 id: "TOPE"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["Lars Wikman"]},
                 id: "TENC"
               },
               %Id3vx.Frame{
                 data: %{encoding: 1, text: ["Lars Wikman"]},
                 id: "TPUB"
               }
             ],
             revision: 0,
             size: 421_307,
             version: 3
           } = tag
  end
end
