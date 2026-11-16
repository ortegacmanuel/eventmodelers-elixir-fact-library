defmodule Library.Slices.ReturnBook.CoreTest do
  use ExUnit.Case, async: true

  import Library.Scenario

  alias Library.Slices.AddBook.BookAdded
  alias Library.Slices.LendBook.BookLent
  alias Library.Slices.ReturnBook.{BookReturned, Decider, ReturnBook}

  describe "A lent book is returned" do
    test "returning a lent book records BookReturned for its loan" do
      given([
        %BookLent{
          loan_id: "l1",
          book_id: "b1",
          member_id: "m1",
          due_on: ~D[2026-11-17],
          lent_at: "2026-11-03T10:00:00Z"
        }
      ])
      |> decide(Decider, %ReturnBook{book_id: "b1", returned_at: "2026-11-10T17:30:00Z"})
      |> expect(
        {:ok,
         [
           %BookReturned{
             loan_id: "l1",
             book_id: "b1",
             member_id: "m1",
             returned_at: "2026-11-10T17:30:00Z"
           }
         ]}
      )
    end
  end

  describe "A book that isn't lent can't be returned" do
    test "returning a book on the shelf is rejected with book_not_lent" do
      given([%BookAdded{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien"}])
      |> decide(Decider, %ReturnBook{book_id: "b1", returned_at: "2026-11-10T17:30:00Z"})
      |> expect({:error, :book_not_lent})
    end
  end

  describe "A book already returned can't be returned twice" do
    test "returning a returned book is rejected with book_not_lent" do
      given([
        %BookLent{
          loan_id: "l1",
          book_id: "b1",
          member_id: "m1",
          due_on: ~D[2026-11-17],
          lent_at: "2026-11-03T10:00:00Z"
        },
        %BookReturned{
          loan_id: "l1",
          book_id: "b1",
          member_id: "m1",
          returned_at: "2026-11-10T17:30:00Z"
        }
      ])
      |> decide(Decider, %ReturnBook{book_id: "b1", returned_at: "2026-11-11T09:00:00Z"})
      |> expect({:error, :book_not_lent})
    end
  end
end
