defmodule Library.Slices.LendBook.Context do
  alias Library.Slices.LendBook.{Core, LendBook}

  require Logger

  def lend_book(params) do
    with {:ok, cmd} <-
           LendBook.new(params, %{
             loan_id: Ecto.UUID.generate(),
             lent_at: DateTime.utc_now() |> DateTime.to_iso8601()
           }),
         {:ok, _events} <- write(cmd) do
      {:ok, cmd.loan_id}
    end
  end

  defp write(cmd) do
    Library.Decide.execute(Library.Application.fact_db(), Core, cmd)
  rescue
    e in RuntimeError ->
      Logger.error("could not write: #{Exception.message(e)}")
      {:error, :store_unavailable}
  end
end
