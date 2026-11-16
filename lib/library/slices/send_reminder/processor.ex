defmodule Library.Slices.SendReminder.Processor do
  use GenServer

  require Logger

  alias Library.Slices.OverdueLoansToRemind.Context, as: Queue
  alias Library.Slices.SendReminder.Context, as: SendReminder

  # Guessed: a loan becomes overdue by the day, so a minute is ample.
  @poll_interval :timer.minutes(1)

  # One sweep at a time: two sweeps would race on the same loans, mail the member
  # twice, and one would only collect :already_reminded.
  @in_flight 1

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def room_for?(in_flight), do: map_size(in_flight) < @in_flight

  @impl true
  def init(opts) do
    state = %{queue: Keyword.get(opts, :queue, Queue), in_flight: %{}}

    if Keyword.get(opts, :start?, true), do: schedule()
    {:ok, state}
  end

  @impl true
  def handle_info(:poll, state) do
    schedule()
    {:noreply, launch(state)}
  end

  def handle_info({ref, result}, state) when is_reference(ref) do
    Process.demonitor(ref, [:flush])
    state = %{state | in_flight: Map.delete(state.in_flight, ref)}

    # Success chains into the next sweep at once; a failure waits for the poll.
    {:noreply, if(result == :ok, do: launch(state), else: state)}
  end

  def handle_info({:DOWN, ref, :process, _pid, :normal}, state),
    do: {:noreply, %{state | in_flight: Map.delete(state.in_flight, ref)}}

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    Logger.error("send reminder sweep failed: #{inspect(reason)}")
    {:noreply, %{state | in_flight: Map.delete(state.in_flight, ref)}}
  end

  def handle_info(_other, state), do: {:noreply, state}

  defp launch(state) do
    if room_for?(state.in_flight) do
      queue = state.queue
      task = Task.Supervisor.async_nolink(Library.TaskSupervisor, fn -> sweep(queue) end)
      %{state | in_flight: Map.put(state.in_flight, task.ref, :sweep)}
    else
      state
    end
  end

  # :done when nothing was pending, so an empty queue doesn't chain into itself.
  defp sweep(queue) do
    case queue.pending() do
      [] -> :done
      items -> if Enum.all?(items, &remind/1), do: :ok, else: :error
    end
  rescue
    e ->
      Logger.warning("send reminder poll failed: #{Exception.message(e)}")
      :error
  end

  defp remind(item) do
    send_mail(item)

    case SendReminder.send_reminder(Map.take(item, [:loan_id, :book_id, :member_id])) do
      {:ok, _loan_id} ->
        true

      {:error, reason} ->
        Logger.error("reminder for loan #{item.loan_id} not recorded: #{inspect(reason)}")
        false
    end
  end

  # The external system: a fake mailer that only logs, so the example runs
  # without credentials. A real one goes here, and a failure returns before
  # SendReminder so the loan stays in the queue for the next poll.
  defp send_mail(item) do
    Logger.info(
      "Reminder sent: member #{item.member_id}, book #{item.book_id}, loan #{item.loan_id}"
    )
  end

  defp schedule, do: Process.send_after(self(), :poll, @poll_interval)
end
