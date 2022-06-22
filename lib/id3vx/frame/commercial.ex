defmodule Id3vx.Frame.Commercial do
  defstruct encoding: :utf16,
            price: nil,
            valid_until: nil,
            contact_url: nil,
            recieved_as: nil,
            seller_name: nil,
            description: nil,
            picture_mime: nil,
            logo: nil

  alias Id3vx.Frame.Commercial

  @type t :: %Commercial{
          encoding: Frame.text_encoding_v3() | Frame.text_encoding_v4(),
          price: String.t(),
          valid_until: String.t(),
          contact_url: String.t(),
          recieved_as: binary(),
          seller_name: String.t(),
          description: String.t(),
          picture_mime: String.t(),
          logo: binary()
        }
end
