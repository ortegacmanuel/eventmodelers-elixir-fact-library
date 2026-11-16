defmodule Library.Slices.ReturnBook.ReturnBook do
  use Library.Command

  embedded_schema do
    field :book_id, :string
    field :returned_at, :string
  end
end
