defmodule Id3vx.Frame.Chapter do
  @moduledoc """
  CHAP frame struct.
  """

  defstruct element_id: nil,
            start_time: nil,
            end_time: nil,
            start_offset: nil,
            end_offset: nil,
            frames: []

  alias Id3vx.Frame
  alias Id3vx.Frame.Chapter

  @type t :: %Chapter{
          element_id: String.t(),
          start_time: integer(),
          end_time: integer(),
          start_offset: integer(),
          end_offset: integer(),
          frames: [%Frame{}]
        }
end
