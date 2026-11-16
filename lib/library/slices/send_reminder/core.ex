defmodule Library.Slices.SendReminder.Core do
  use Library.StateChange

  alias Library.Slices.SendReminder.{ReminderSent, SendReminder}

  @impl true
  def query(%SendReminder{} = cmd) do
    Fact.QueryItem.types(["BookReturned", "ReminderSent"])
    |> Fact.QueryItem.tags(["loan:#{cmd.loan_id}"])
  end

  @impl true
  def initial_state, do: %{returned: false, reminded: false}

  @impl true
  def apply_event(state, %{"event_type" => "BookReturned"}), do: %{state | returned: true}
  def apply_event(state, %{"event_type" => "ReminderSent"}), do: %{state | reminded: true}
  def apply_event(state, _), do: state

  @impl true
  def execute(_cmd, %{reminded: true}), do: {:error, :already_reminded}
  def execute(_cmd, %{returned: true}), do: {:error, :loan_closed}

  def execute(%SendReminder{} = cmd, _state) do
    {:ok,
     [
       %ReminderSent{
         loan_id: cmd.loan_id,
         book_id: cmd.book_id,
         member_id: cmd.member_id,
         sent_at: cmd.sent_at
       }
     ]}
  end
end
