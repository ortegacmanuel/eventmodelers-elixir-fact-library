defmodule Library.Slices.AddBook.CoreTest do
  use ExUnit.Case, async: true

  import Library.Scenario

  alias Library.Slices.AddBook.{AddBook, BookAdded, Decider}

  describe "A book is added to the catalogue" do
    test "adding a book records BookAdded with its title and author" do
      given([])
      |> decide(Decider, %AddBook{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien"})
      |> expect(
        {:ok, [%BookAdded{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien"}]}
      )
    end
  end
end
