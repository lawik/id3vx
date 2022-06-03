defmodule Id3vx.Tag do
  @moduledoc """
  The base data structure for the ID3 tag.
  """

  defstruct version: nil,
            revision: nil,
            flags: nil,
            size: nil,
            extended_header: nil,
            footer: nil,
            frames: nil

  alias Id3vx.Tag
  alias Id3vx.Frame
  alias Id3vx.FrameFlags

  @type t :: %Tag{
          version: 3 | 4,
          revision: integer(),
          flags: %Id3vx.TagFlags{},
          size: integer(),
          extended_header: %Id3vx.ExtendedHeaderV3{} | %Id3vx.ExtendedHeaderV4{},
          footer: term(),
          frames: [Id3vx.Frame.t()]
        }

  def create(version) do
    %Tag{version: version, revision: 0, frames: []}
  end

  def add_text_frame(container, frame_id, text) when is_binary(text) do
    add_text_frame(container, frame_id, [text])
  end

  def add_text_frame(container, "T" <> _ = frame_id, text) when is_list(text) do
    frame = %Frame{
      id: frame_id,
      flags: FrameFlags.all_false(),
      label: Id3vx.Frame.Labels.from_id(frame_id),
      data: %Frame.Text{
        encoding: :utf16,
        text: text
      }
    }

    %{container | frames: [frame | container.frames]}
  end
end
