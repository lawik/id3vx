defmodule Id3vx.Frame.RecommendedBufferSize do
  defstruct buffer_size: nil,
            embedded_info: false,
            offset: nil

  alias Id3vx.Frame.RecommendedBufferSize

  @type t :: %RecommendedBufferSize{
          buffer_size: String.t(),
          embedded_info: boolean(),
          offset: String.t()
        }
end
