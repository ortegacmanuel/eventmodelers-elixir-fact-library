defmodule Library.Slices.SendReminder.Processor do
  use GenServer

  require Logger

  alias Library.Slices.OverdueLoansToRemind.Context, as: Queue
  alias Library.Slices.SendReminder.Context, as: SendReminder

  # Guessed: a loan becomes overdue by the day, so a minute is ample.
  @poll_interval :timer.minutes(1)

  # 1: neither the board nor the mailer states a limit (the mailer is a fake
  # that only logs).
  @in_flight 1

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # The queue is held as a value, not called through the alias: the slice
  # compiles before the queue slice exists, and a test can pass its own.
  @impl true
  def init(opts) do
    if Keyword.get(opts, :start?, true), do: schedule()
    {:ok, %{queue: Keyword.get(opts, :queue, Queue), in_flight: %{}}}
  end

  @impl true
  def handle_info(:poll, state) do
    schedule()
    {:noreply, launch(state)}
  end

  # Tasks use `async_nolink`: their result and their crash arrive as messages,
  # and you have to handle them or the GenServer fills up with unread mail.
  def handle_info({ref, result}, state) when is_reference(ref) do
    Process.demonitor(ref, [:flush])
    state = %{state | in_flight: Map.delete(state.in_flight, ref)}

    # A success pulls the next loan at once; a failure waits for the poll.
    {:noreply, if(result == :ok, do: launch(state), else: state)}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    Logger.error("send reminder task failed: #{inspect(reason)}")
    {:noreply, %{state | in_flight: Map.delete(state.in_flight, ref)}}
  end

  def handle_info(_other, state), do: {:noreply, state}

  # Pure: whether one more loan may start. Tested without the mailer.
  def room_for?(in_flight, loan_id) do
    map_size(in_flight) < @in_flight and loan_id not in Map.values(in_flight)
  end

  defp schedule, do: Process.send_after(self(), :poll, @poll_interval)

  # A loan not launched stays pending in the durable queue for the next poll.
  defp launch(state) do
    in_flight =
      Enum.reduce(state.queue.pending(), state.in_flight, fn item, in_flight ->
        if room_for?(in_flight, item.loan_id) do
          task = Task.Supervisor.async_nolink(Library.TaskSupervisor, fn -> process(item) end)
          Map.put(in_flight, task.ref, item.loan_id)
        else
          in_flight
        end
      end)

    %{state | in_flight: in_flight}
  rescue
    e ->
      Logger.warning("send reminder poll failed: #{Exception.message(e)}")
      state
  end

  # :ok or :error — the processor needs to tell them apart (see above).
  defp process(item) do
    with :ok <- send_mail(item),
         {:ok, _loan_id} <- SendReminder.execute(Map.take(item, [:loan_id, :book_id, :member_id])) do
      :ok
    else
      error ->
        Logger.error("reminder for loan #{item.loan_id} not recorded: #{inspect(error)}")
        :error
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
end
