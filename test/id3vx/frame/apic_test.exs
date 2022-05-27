defmodule Id3vx.Frame.ApicTest do
  use ExUnit.Case
  alias Id3vx.Frame

  test "parse apic from binary" do
    binary = File.read!("test/binary-samples/apic.bin")

    assert %Frame{data: %{description: "image", mime_type: "image/jpg", picture_type: :other}} =
             Frame.parse("APIC", nil, binary) |> IO.inspect()
  end
end
