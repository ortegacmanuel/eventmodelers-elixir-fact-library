defmodule Library.Slices.MemberSLoans.Context do
  alias Library.Slices.MemberSLoans.ReadModel

  def member_s_loans(member_id),
    do: Library.StateView.read(Library.Application.fact_db(), ReadModel, member_id)
end
