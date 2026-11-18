defmodule LibraryWeb.MemberLoansLive do
  use LibraryWeb, :live_view

  alias Library.Slices.MemberSLoans

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Member's loans")
     |> stream_configure(:loans, dom_id: &"loan-#{&1.loan_id}")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    member_id = String.trim(params["member_id"] || "")
    loans = if member_id == "", do: [], else: MemberSLoans.Context.read(member_id)

    {:noreply,
     socket
     |> assign(:member_id, member_id)
     |> assign(:search, to_form(%{"member_id" => member_id}, as: :member))
     |> assign(:empty?, loans == [])
     |> stream(:loans, loans, reset: true)}
  end

  @impl true
  def handle_event("show", %{"member" => %{"member_id" => member_id}}, socket),
    do: {:noreply, push_patch(socket, to: ~p"/members/loans?#{[member_id: member_id]}")}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>Member's loans</.header>

      <.form for={@search} id="member-search" phx-submit="show" class="flex items-end gap-2">
        <div class="flex-1">
          <.input field={@search[:member_id]} label="Member" placeholder="M-1042" />
        </div>
        <div class="mb-2"><.button variant="primary">Show loans</.button></div>
      </.form>

      <p :if={@member_id != "" and @empty?} id="no-loans" class="text-base-content/70">
        {@member_id} has no books on loan.
      </p>

      <div :if={@member_id != "" and not @empty?}>
        <.table id="loans" rows={@streams.loans}>
          <:col :let={{_id, loan}} label="Title">{loan.title}</:col>
          <:col :let={{_id, loan}} label="Due on">{loan.due_on}</:col>
        </.table>
        <p class="mt-2 text-sm text-base-content/70">A member can hold two books at a time.</p>
      </div>
    </Layouts.app>
    """
  end
end
