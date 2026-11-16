defmodule Library.Slices.CorrectBookTitle.CoreTest do
  use ExUnit.Case, async: true

  import Library.Scenario

  alias Library.Slices.AddBook.BookAdded
  alias Library.Slices.CorrectBookTitle.{BookTitleCorrected, Decider, CorrectBookTitle}

  describe "The title of an added book is corrected" do
    test "correcting an added book's title records BookTitleCorrected" do
      given([%BookAdded{book_id: "b1", title: "The Hobit", author: "J. R. R. Tolkien"}])
      |> decide(Decider, %CorrectBookTitle{book_id: "b1", title: "The Hobbit"})
      |> expect({:ok, [%BookTitleCorrected{book_id: "b1", title: "The Hobbit"}]})
    end
  end

  describe "A book that was never added can't be corrected" do
    test "correcting an unknown book is rejected with book_not_found" do
      given([])
      |> decide(Decider, %CorrectBookTitle{book_id: "b9", title: "The Hobbit"})
      |> expect({:error, :book_not_found})
    end
  end
end
