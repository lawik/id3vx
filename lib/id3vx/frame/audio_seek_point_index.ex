defmodule Id3vx.Frame.AudioSeekPointIndex do
  @moduledoc """
    ASPI frame struct
  """
  defstruct indexed_data_start: nil,
            indexed_data_length: nil,
            number_of_index_points: nil,
            bits_per_index_point: nil,
            fraction_at_index: nil

  alias Id3vx.Frame.AudioSeekPointIndex

  @type t :: %AudioSeekPointIndex{
          indexed_data_start: integer(),
          indexed_data_length: integer(),
          number_of_index_points: integer(),
          bits_per_index_point: integer(),
          fraction_at_index: binary()
        }
end
