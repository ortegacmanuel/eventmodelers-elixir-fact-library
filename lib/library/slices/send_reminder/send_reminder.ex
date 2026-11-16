defmodule Library.Slices.SendReminder.SendReminder do
  use Library.Command

  embedded_schema do
    field :loan_id, :string
    field :book_id, :string
    field :member_id, :string
    field :sent_at, :utc_datetime
  end
end
