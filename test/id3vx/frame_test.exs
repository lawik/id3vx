defmodule Id3vx.FrameTest do
  use ExUnit.Case
  alias Id3vx.Frame

  describe "text parsing" do
    test "parse default encoded text" do
      encoding = :iso8859_1

      text_frame_binary = <<76, 97, 114, 115, 32, 87, 105, 107, 109, 97, 110>>
      assert "Lars Wikman" = Frame.decode_string(encoding, text_frame_binary)
    end

    test "parse utf-16 encoded text" do
      # UTF-16
      encoding = :utf16

      text_frame_binary =
        <<255, 254, 76, 0, 97, 0, 114, 0, 115, 0, 32, 0, 87, 0, 105, 0, 107, 0, 109, 0, 97, 0,
          110, 0>>

      assert "Lars Wikman" = Frame.decode_string(encoding, text_frame_binary)
    end
  end
end
