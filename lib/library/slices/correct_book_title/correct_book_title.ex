defmodule Library.Slices.CorrectBookTitle.CorrectBookTitle do
  use Library.Command

  embedded_schema do
    field :book_id, :string
    field :title, :string
  end
end
