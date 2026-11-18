defmodule Library.Slices.ReturnBook.Context do
  alias Library.Slices.ReturnBook.{Decider, ReturnBook}

  require Logger

  def execute(params) do
    with {:ok, cmd} <-
           ReturnBook.new(params, %{returned_at: DateTime.utc_now() |> DateTime.to_iso8601()}),
         {:ok, [returned]} <- write(cmd) do
      {:ok, returned.loan_id}
    end
  end

  defp write(cmd) do
    Library.Decide.execute(Library.Application.fact_db(), Decider, cmd)
  rescue
    e in RuntimeError ->
      Logger.error("could not write: #{Exception.message(e)}")
      {:error, :store_unavailable}
  end
end
