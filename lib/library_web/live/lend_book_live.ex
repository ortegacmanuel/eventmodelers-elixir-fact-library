defmodule LibraryWeb.LendBookLive do
  use LibraryWeb, :live_view

  alias Library.Slices.{Catalogue, LendBook}

  @impl true
  def mount(params, _session, socket) do
    available = Enum.filter(Catalogue.Context.read(), & &1.available)

    {:ok,
     socket
     |> assign(:page_title, "Lend a book")
     |> assign(:options, Enum.map(available, &{"#{&1.title} — #{&1.author}", &1.book_id}))
     |> assign(:error, nil)
     |> assign_form(Map.take(params, ["book_id"]), nil)}
  end

  @impl true
  def handle_event("validate", %{"loan" => params}, socket),
    do: {:noreply, assign_form(socket, params, :validate)}

  def handle_event("save", %{"loan" => params}, socket) do
    case LendBook.Context.execute(params) do
      {:ok, _loan_id} ->
        {:noreply,
         socket
         |> put_flash(:info, "Lent to #{params["member_id"]} until #{params["due_on"]}.")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :loan, action: :insert))}

      {:error, reason} ->
        {:noreply, socket |> assign(:error, reason) |> assign_form(params, :insert)}
    end
  end

  defp assign_form(socket, params, action) do
    changeset = LendBook.LendBook.changeset(params)
    assign(socket, :form, to_form(changeset, as: :loan, action: action))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>Lend a book</.header>

      <div :if={@error} id="error" role="alert" class="alert alert-error">
        {LibraryWeb.DomainErrors.message(@error)}
      </div>

      <p :if={@options == []} id="nothing-to-lend" class="text-base-content/70">
        No book is available right now.
      </p>

      <.form :if={@options != []} for={@form} id="lend-book" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:book_id]}
          type="select"
          label="Book"
          prompt="Choose a book"
          options={@options}
        />
        <p class="-mt-1 mb-2 text-sm text-base-content/70">Only books that are available.</p>
        <.input field={@form[:member_id]} label="Member" />
        <.input field={@form[:due_on]} type="date" label="Due on" />
        <div class="mt-6 flex gap-2">
          <.button variant="primary" phx-disable-with="Lending…">Lend book</.button>
          <.button navigate={~p"/"}>Cancel</.button>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
