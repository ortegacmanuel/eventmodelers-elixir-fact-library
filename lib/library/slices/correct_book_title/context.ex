defmodule Library.Slices.CorrectBookTitle.Context do
  alias Library.Slices.CorrectBookTitle.{Core, CorrectBookTitle}

  require Logger

  def correct_book_title(params) do
    with {:ok, cmd} <- CorrectBookTitle.new(params),
         {:ok, _events} <- write(cmd) do
      {:ok, cmd.book_id}
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
