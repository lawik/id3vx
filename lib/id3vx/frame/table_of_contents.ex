defmodule Id3vx.Frame.TableOfContents do
  @moduledoc """
  CTOC frame struct.
  """

  defstruct element_id: nil,
            top_level: nil,
            ordered: nil,
            child_elements: [],
            frames: []

  alias Id3vx.Frame
  alias Id3vx.Frame.TableOfContents

  @type t :: %TableOfContents{
          element_id: String.t(),
          top_level: boolean(),
          ordered: boolean(),
          child_elements: [String.t()],
          frames: [%Frame{}]
        }
end
