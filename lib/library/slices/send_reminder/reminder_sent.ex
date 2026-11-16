defmodule Library.Slices.SendReminder.ReminderSent do
  @derive {Library.Event, type: "ReminderSent", tags: [:loan_id]}
  defstruct [:loan_id, :book_id, :member_id, :sent_at]
end
