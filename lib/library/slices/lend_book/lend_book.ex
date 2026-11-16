defmodule Library.Slices.LendBook.LendBook do
  use Library.Command

  embedded_schema do
    field :loan_id, :string
    field :book_id, :string
    field :member_id, :string
    field :due_on, :date
    field :lent_at, :string
  end
end
