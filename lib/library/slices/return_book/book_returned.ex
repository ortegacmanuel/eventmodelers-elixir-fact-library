defmodule Library.Slices.ReturnBook.BookReturned do
  @derive {Library.Event, type: "BookReturned", tags: [:loan_id, :book_id, :member_id]}
  defstruct [:loan_id, :book_id, :member_id, :returned_at]
end
