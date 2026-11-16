defmodule Library.Slices.MemberSLoans.Context do
  alias Library.Slices.MemberSLoans.Core

  def member_s_loans(member_id),
    do: Library.StateView.read(Library.Application.fact_db(), Core, member_id)
end
