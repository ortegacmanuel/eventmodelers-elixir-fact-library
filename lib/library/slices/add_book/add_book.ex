defmodule Library.Slices.AddBook.AddBook do
  use Library.Command

  embedded_schema do
    field :book_id, :string
    field :title, :string
    field :author, :string
  end
end
