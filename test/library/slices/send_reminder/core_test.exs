defmodule Library.Slices.SendReminder.CoreTest do
  use ExUnit.Case, async: true

  import Library.Scenario

  alias Library.Slices.SendReminder.{Core, ReminderSent, SendReminder}

  describe "An overdue loan gets its reminder" do
    test "reminding an open loan records ReminderSent" do
      given([
        %{
          type: "BookLent",
          data: %{
            loan_id: "l3",
            book_id: "b3",
            member_id: "m2",
            due_on: "2026-11-18",
            lent_at: "2026-11-04T09:15:00Z"
          },
          tags: ["loan:l3", "book:b3", "member:m2"]
        }
      ])
      |> decide(Core, %SendReminder{
        loan_id: "l3",
        book_id: "b3",
        member_id: "m2",
        sent_at: ~U[2026-11-19 08:00:00Z]
      })
      |> expect(
        {:ok,
         [
           %ReminderSent{
             loan_id: "l3",
             book_id: "b3",
             member_id: "m2",
             sent_at: ~U[2026-11-19 08:00:00Z]
           }
         ]}
      )
    end
  end

  describe "A loan gets only one reminder" do
    test "reminding an already reminded loan is rejected with already_reminded" do
      given([
        %{
          type: "BookLent",
          data: %{
            loan_id: "l3",
            book_id: "b3",
            member_id: "m2",
            due_on: "2026-11-18",
            lent_at: "2026-11-04T09:15:00Z"
          },
          tags: ["loan:l3", "book:b3", "member:m2"]
        },
        %ReminderSent{
          loan_id: "l3",
          book_id: "b3",
          member_id: "m2",
          sent_at: ~U[2026-11-19 08:00:00Z]
        }
      ])
      |> decide(Core, %SendReminder{
        loan_id: "l3",
        book_id: "b3",
        member_id: "m2",
        sent_at: ~U[2026-11-19 08:00:05Z]
      })
      |> expect({:error, :already_reminded})
    end
  end

  describe "A loan returned before the reminder gets none" do
    test "reminding a returned loan is rejected with loan_closed" do
      given([
        %{
          type: "BookLent",
          data: %{
            loan_id: "l3",
            book_id: "b3",
            member_id: "m2",
            due_on: "2026-11-18",
            lent_at: "2026-11-04T09:15:00Z"
          },
          tags: ["loan:l3", "book:b3", "member:m2"]
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
      |> decide(Core, %SendReminder{
        loan_id: "l3",
        book_id: "b3",
        member_id: "m2",
        sent_at: ~U[2026-11-19 08:00:00Z]
      })
      |> expect({:error, :loan_closed})
    end
  end
end
