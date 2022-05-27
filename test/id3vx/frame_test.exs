defmodule Id3vx.FrameTest do
  use ExUnit.Case

  describe "text parsing" do
    test "parse default encoded text" do
      # ISO-8859-1
      encoding = 0

      text_frame_binary =
        <<encoding>> <>
          <<76, 97, 114, 115, 32, 87, 105, 107, 109, 97, 110>>

      assert %{encoding: :iso8859_1, text: ["Lars Wikman"]} =
               Id3vx.Frame.parse_text(nil, text_frame_binary)
    end

    test "parse utf-16 encoded text" do
      # UTF-16
      encoding = 1

      text_frame_binary =
        <<encoding>> <>
          <<255, 254, 76, 0, 97, 0, 114, 0, 115, 0, 32, 0, 87, 0, 105, 0, 107, 0, 109, 0, 97, 0,
            110, 0>>

      assert %{encoding: :utf16, text: ["Lars Wikman"]} =
               Id3vx.Frame.parse_text(nil, text_frame_binary)
    end

    test "parse multiple pieces of default encoded text" do
      # ISO-8859-1
      encoding = 0

      text_frame_binary =
        <<encoding>> <>
          <<76, 97, 114, 115, 32, 87, 105, 107, 109, 97, 110, 0, 76, 97, 114, 115, 32, 87, 105,
            107, 109, 97, 110>>

      assert %{encoding: :iso8859_1, text: ["Lars Wikman", "Lars Wikman"]} =
               Id3vx.Frame.parse_text(nil, text_frame_binary)
    end

    test "parse multiple pieces of utf-16 encoded text" do
      # UTF-16
      encoding = 1

      text_frame_binary =
        <<encoding>> <>
          <<255, 254, 76, 0, 97, 0, 114, 0, 115, 0, 32, 0, 87, 0, 105, 0, 107, 0, 109, 0, 97, 0,
            110, 0, 0, 0, 255, 254, 76, 0, 97, 0, 114, 0, 115, 0, 32, 0, 87, 0, 105, 0, 107, 0,
            109, 0, 97, 0, 110, 0>>

      assert %{encoding: :utf16, text: ["Lars Wikman", "Lars Wikman"]} =
               Id3vx.Frame.parse_text(nil, text_frame_binary)
    end
  end
end
