defmodule Id3vx.Frame.Reverb do
  @moduledoc """
  RVRB frame struct
  """

  defstruct reverb_left: nil,
            reverb_right: nil,
            bounces_left: nil,
            bounces_right: nil,
            feedback_left_to_left: nil,
            feedback_left_to_right: nil,
            feedback_right_to_right: nil,
            feedback_right_to_left: nil,
            premix_left_to_right: nil,
            premix_right_to_left: nil

  alias Id3vx.Frame.Reverb

  @type t :: %Reverb{
          reverb_left: integer(),
          reverb_right: integer(),
          bounces_left: integer(),
          bounces_right: integer(),
          feedback_left_to_left: integer(),
          feedback_left_to_right: integer(),
          feedback_right_to_right: integer(),
          feedback_right_to_left: integer(),
          premix_left_to_right: integer(),
          premix_right_to_left: integer()
        }
end
