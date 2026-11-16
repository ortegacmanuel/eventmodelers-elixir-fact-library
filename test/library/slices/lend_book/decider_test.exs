defmodule Library.Slices.LendBook.CoreTest do
  use ExUnit.Case, async: true

  import Library.Scenario

  alias Library.Slices.AddBook.BookAdded
  alias Library.Slices.LendBook.{BookLent, Decider, LendBook}

  describe "An added book is lent to a member" do
    test "lending an added book records BookLent" do
      given([%BookAdded{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien"}])
      |> decide(Decider, %LendBook{
        loan_id: "l1",
        book_id: "b1",
        member_id: "m1",
        due_on: ~D[2026-11-17],
        lent_at: "2026-11-03T10:00:00Z"
      })
      |> expect(
        {:ok,
         [
           %BookLent{
             loan_id: "l1",
             book_id: "b1",
             member_id: "m1",
             due_on: ~D[2026-11-17],
             lent_at: "2026-11-03T10:00:00Z"
           }
         ]}
      )
    end
  end

  describe "A book that was never added can't be lent" do
    test "lending an unknown book is rejected with book_not_found" do
      given([])
      |> decide(Decider, %LendBook{
        loan_id: "l1",
        book_id: "b9",
        member_id: "m1",
        due_on: ~D[2026-11-17],
        lent_at: "2026-11-03T10:00:00Z"
      })
      |> expect({:error, :book_not_found})
    end
  end

  describe "A book already lent can't be lent again" do
    test "lending a book on loan is rejected with book_already_lent" do
      given([
        %BookAdded{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien"},
        %BookLent{
          loan_id: "l1",
          book_id: "b1",
          member_id: "m1",
          due_on: ~D[2026-11-17],
          lent_at: "2026-11-03T10:00:00Z"
        }
      ])
      |> decide(Decider, %LendBook{
        loan_id: "l2",
        book_id: "b1",
        member_id: "m2",
        due_on: ~D[2026-11-18],
        lent_at: "2026-11-04T09:00:00Z"
      })
      |> expect({:error, :book_already_lent})
    end
  end

  describe "A returned book can be lent again" do
    test "lending a returned book records BookLent" do
      given([
        %BookAdded{book_id: "b1", title: "The Hobbit", author: "J. R. R. Tolkien"},
        %BookLent{
          loan_id: "l1",
          book_id: "b1",
          member_id: "m1",
          due_on: ~D[2026-11-17],
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
      |> decide(Decider, %LendBook{
        loan_id: "l2",
        book_id: "b1",
        member_id: "m2",
        due_on: ~D[2026-11-25],
        lent_at: "2026-11-11T09:00:00Z"
      })
      |> expect(
        {:ok,
         [
           %BookLent{
             loan_id: "l2",
             book_id: "b1",
             member_id: "m2",
             due_on: ~D[2026-11-25],
             lent_at: "2026-11-11T09:00:00Z"
           }
         ]}
      )
    end
  end

  describe "A member holding 2 books can't borrow a third" do
    test "lending a third book to a member is rejected with member_holds_two_books" do
      given([
        %BookAdded{book_id: "b3", title: "Dune", author: "Frank Herbert"},
        %BookLent{
          loan_id: "l1",
          book_id: "b1",
          member_id: "m1",
          due_on: ~D[2026-11-17],
          lent_at: "2026-11-03T10:00:00Z"
        },
        %BookLent{
          loan_id: "l2",
          book_id: "b2",
          member_id: "m1",
          due_on: ~D[2026-11-18],
          lent_at: "2026-11-04T10:00:00Z"
        }
      ])
      |> decide(Decider, %LendBook{
        loan_id: "l3",
        book_id: "b3",
        member_id: "m1",
        due_on: ~D[2026-11-19],
        lent_at: "2026-11-05T10:00:00Z"
      })
      |> expect({:error, :member_holds_two_books})
    end
  end

  describe "A member who returned one of 2 books can borrow another" do
    test "lending after a return records BookLent" do
      given([
        %BookAdded{book_id: "b3", title: "Dune", author: "Frank Herbert"},
        %BookLent{
          loan_id: "l1",
          book_id: "b1",
          member_id: "m1",
          due_on: ~D[2026-11-17],
          lent_at: "2026-11-03T10:00:00Z"
        },
        %BookLent{
          loan_id: "l2",
          book_id: "b2",
          member_id: "m1",
          due_on: ~D[2026-11-18],
          lent_at: "2026-11-04T10:00:00Z"
        },
        %{
          type: "BookReturned",
          data: %{
            loan_id: "l1",
            book_id: "b1",
            member_id: "m1",
            returned_at: "2026-11-05T09:00:00Z"
          },
          tags: ["loan:l1", "book:b1", "member:m1"]
        }
      ])
      |> decide(Decider, %LendBook{
        loan_id: "l3",
        book_id: "b3",
        member_id: "m1",
        due_on: ~D[2026-11-19],
        lent_at: "2026-11-05T10:00:00Z"
      })
      |> expect(
        {:ok,
         [
           %BookLent{
             loan_id: "l3",
             book_id: "b3",
             member_id: "m1",
             due_on: ~D[2026-11-19],
             lent_at: "2026-11-05T10:00:00Z"
           }
         ]}
      )
    end
  end
end
