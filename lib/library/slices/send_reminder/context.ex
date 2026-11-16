defmodule Library.Slices.SendReminder.Context do
  alias Library.Slices.SendReminder.{Core, SendReminder}

  require Logger

  def send_reminder(params) do
    with {:ok, cmd} <-
           SendReminder.new(params, %{sent_at: DateTime.utc_now() |> DateTime.truncate(:second)}),
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
