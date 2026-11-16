defmodule Library.Slices.LendBook.BookLent do
  @derive {Library.Event, type: "BookLent", tags: [:loan_id, :book_id, :member_id]}
  defstruct [:loan_id, :book_id, :member_id, :due_on, :lent_at]
end
