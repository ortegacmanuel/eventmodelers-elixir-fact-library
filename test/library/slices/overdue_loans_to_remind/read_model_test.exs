defmodule Library.Slices.OverdueLoansToRemind.CoreTest do
  use ExUnit.Case, async: true

  import Library.Scenario

  alias Library.Slices.LendBook.BookLent
  alias Library.Slices.OverdueLoansToRemind.ReadModel
  alias Library.Slices.SendReminder.ReminderSent

  describe "A loan past its due date waits for its reminder" do
    test "only the loan due before today is listed" do
      given([
        %BookLent{
          loan_id: "l1",
          book_id: "b1",
          member_id: "m1",
          due_on: ~D[2026-11-19],
          lent_at: ~U[2026-11-03 10:00:00Z]
        },
        %BookLent{
          loan_id: "l3",
          book_id: "b3",
          member_id: "m2",
          due_on: ~D[2026-11-18],
          lent_at: ~U[2026-11-04 09:15:00Z]
        }
      ])
      |> read(ReadModel, ~D[2026-11-19])
      |> expect([%{loan_id: "l3", book_id: "b3", member_id: "m2", due_on: ~D[2026-11-18]}])
    end
  end

  describe "A reminded loan leaves the list" do
    test "an overdue loan already reminded is not listed" do
      given([
        %BookLent{
          loan_id: "l3",
          book_id: "b3",
          member_id: "m2",
          due_on: ~D[2026-11-18],
          lent_at: ~U[2026-11-04 09:15:00Z]
        },
        %ReminderSent{
          loan_id: "l3",
          book_id: "b3",
          member_id: "m2",
          sent_at: ~U[2026-11-19 08:00:00Z]
        }
      ])
      |> read(ReadModel, ~D[2026-11-20])
      |> expect([])
    end
  end

  describe "A returned loan leaves the list" do
    test "an overdue loan returned is not listed" do
      given([
        %BookLent{
          loan_id: "l3",
          book_id: "b3",
          member_id: "m2",
          due_on: ~D[2026-11-18],
          lent_at: ~U[2026-11-04 09:15:00Z]
        },
        %{
          type: "BookReturned",
          data: %{
            loan_id: "l3",
            book_id: "b3",
            member_id: "m2",
            returned_at: "2026-11-19T07:55:00Z"
          },
          tags: ["loan:l3", "book:b3", "member:m2"]
        }
      ])
      |> read(ReadModel, ~D[2026-11-20])
      |> expect([])
    end
  end
end
