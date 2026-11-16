defmodule Library.Slices.CorrectBookTitle.BookTitleCorrected do
  @derive {Library.Event, type: "BookTitleCorrected", tags: [:book_id]}
  defstruct [:book_id, :title]
end
