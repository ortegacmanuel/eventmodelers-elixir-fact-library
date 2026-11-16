defmodule Library.Slices.Catalogue.CoreTest do
  use ExUnit.Case, async: true

  import Library.Scenario

  alias Library.Slices.AddBook.BookAdded
  alias Library.Slices.Catalogue.ReadModel

  describe "Every added book, with whether it can be lent" do
    test "a lent book is not available, one never lent is" do
      given([
        %BookAdded{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien"},
        %BookAdded{book_id: "b2", title: "Dune", author: "Frank Herbert"},
        %{
          type: "BookLent",
          data: %{
            loan_id: "l1",
            book_id: "b1",
            member_id: "m1",
            due_on: "2026-11-17",
            lent_at: "2026-11-03T10:00:00Z"
          },
          tags: ["loan:l1", "book:b1", "member:m1"]
        }
      ])
      |> read(ReadModel, nil)
      |> expect([
        %{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien", available: false},
        %{book_id: "b2", title: "Dune", author: "Frank Herbert", available: true}
      ])
    end
  end

  describe "A returned book is available again" do
    test "a book lent and returned is available" do
      given([
        %BookAdded{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien"},
        %{
          type: "BookLent",
          data: %{
            loan_id: "l1",
            book_id: "b1",
            member_id: "m1",
            due_on: "2026-11-17",
            lent_at: "2026-11-03T10:00:00Z"
          },
          tags: ["loan:l1", "book:b1", "member:m1"]
        },
        %{
          type: "BookReturned",
          data: %{
            loan_id: "l1",
            book_id: "b1",
            member_id: "m1",
            returned_at: "2026-11-10T17:30:00Z"
          },
          tags: ["loan:l1", "book:b1", "member:m1"]
        }
      ])
      |> read(ReadModel, nil)
      |> expect([
        %{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien", available: true}
      ])
    end
  end

  describe "A corrected title replaces the old one" do
    test "the catalogue shows the corrected title" do
      given([
        %BookAdded{book_id: "b1", title: "The Hobit", author: "J. R. R. Tolkien"},
        %{
          type: "BookTitleCorrected",
          data: %{book_id: "b1", title: "The Hobbit"},
          tags: ["book:b1"]
        }
      ])
      |> read(ReadModel, nil)
      |> expect([
        %{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien", available: true}
      ])
    end
  end

  describe "An empty library has an empty catalogue" do
    test "no books, no rows" do
      given([])
      |> read(ReadModel, nil)
      |> expect([])
    end
  end
end
