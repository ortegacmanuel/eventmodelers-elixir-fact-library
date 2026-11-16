defmodule Library.Slices.AddBook.BookAdded do
  @derive {Library.Event, type: "BookAdded", tags: [:book_id]}
  defstruct [:book_id, :title, :author]
end
