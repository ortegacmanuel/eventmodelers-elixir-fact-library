defmodule Library.Slices.MemberSLoans.CoreTest do
  use ExUnit.Case, async: true

  import Library.Scenario

  alias Library.Slices.AddBook.BookAdded
  alias Library.Slices.CorrectBookTitle.BookTitleCorrected
  alias Library.Slices.LendBook.BookLent
  alias Library.Slices.MemberSLoans.ReadModel

  describe "A member's open loans, with the book's current title" do
    test "only m1's loan, titled as corrected" do
      given([
        %BookAdded{book_id: "b1", title: "The Hobit", author: "J. R. R. Tolkien"},
        %BookTitleCorrected{book_id: "b1", title: "The Hobbit"},
        %BookLent{
          loan_id: "l1",
          book_id: "b1",
          member_id: "m1",
          due_on: "2026-11-17",
          lent_at: "2026-11-03T10:00:00Z"
        },
        %BookAdded{book_id: "b2", title: "Dune", author: "Frank Herbert"},
        %BookLent{
          loan_id: "l2",
          book_id: "b2",
          member_id: "m2",
          due_on: "2026-11-18",
          lent_at: "2026-11-04T10:00:00Z"
        }
      ])
      |> read(ReadModel, "m1")
      |> expect([%{loan_id: "l1", book_id: "b1", title: "The Hobbit", due_on: "2026-11-17"}])
    end
  end

  describe "A returned book leaves the member's loans" do
    test "a lent and returned book is not listed" do
      given([
        %BookAdded{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien"},
        %BookLent{
          loan_id: "l1",
          book_id: "b1",
          member_id: "m1",
          due_on: "2026-11-17",
          lent_at: "2026-11-03T10:00:00Z"
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
      |> read(ReadModel, "m1")
      |> expect([])
    end
  end
end
