defmodule Id3vx.Frame.InvolvedPeopleList do
  @moduledoc """
  InvolvedPeopleList frame struct.
  """

  defstruct encoding: :utf16,
            people_list_strings: nil

  alias Id3vx.Frame.InvolvedPeopleList

  @type t :: %InvolvedPeopleList{
          encoding: Frame.text_encoding_v3() | Frame.text_encoding_v4(),
          people_list_strings: String.t()
        }
end
