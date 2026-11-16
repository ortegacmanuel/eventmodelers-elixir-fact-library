defmodule LibraryWeb.DomainErrors do
  # The domain's rejections, in the words the screens show.
  def message(:book_not_found), do: "That book isn't in the catalogue."
  def message(:book_already_lent), do: "That book is already on loan."
  def message(:member_holds_two_books), do: "This member already holds two books."
  def message(:book_not_lent), do: "That book isn't on loan."

  def message(:store_unavailable),
    do: "Nothing was saved: the library's records aren't reachable. Try again."
end
