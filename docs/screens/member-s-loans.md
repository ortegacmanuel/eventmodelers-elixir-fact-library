# Screen: A member's loans

Slice `Member's loans` · node `ae4b55fa-08cf-47ff-83a1-bbd73bacb51d` · written by the loop on 2026-11-16.

Mockup: designed on the board — `get_node` with the id above (a member id input with a "Show loans" button, then a table of Title / Due on).

## How it's entered

```elixir
Library.Slices.MemberSLoans.Context.member_s_loans(member_id :: String.t()) ::
  [%{loan_id: String.t(), book_id: String.t(), title: String.t() | nil, due_on: String.t()}]
```

Returns the member's open loans in the order they were lent. The member id is the argument; it isn't repeated in the rows.

## What it returns

| field | type | | what it is |
|---|---|---|---|
| `loan_id` | `UUID` | | the loan, from `BookLent.loanId` |
| `book_id` | `UUID` | | the lent book, from `BookLent.bookId` |
| `title` | `String` | optional | the book's current title: `BookAdded.title`, replaced by any later `BookTitleCorrected`. `nil` only if no `BookAdded` exists for the book (shouldn't happen: lending checks it) |
| `due_on` | `Date` | | from `BookLent.dueOn`, an ISO-8601 date string (`"2026-11-17"`) |

## What it sends back

Nothing. This slice is read-only.

## States to render

- **No member entered yet**: nothing to read; the screen decides.
- **Empty list**: the member has no open loans, or the id is unknown. The domain doesn't tell these apart.
- **One or two rows**: open loans. Lending caps a member at two books (`:member_holds_two_books` in Lend book).

## What the board says about this screen

No description on the screen node. The mockup's footer reads: "A member can hold two books at a time."

## What the domain does NOT give you

- **No member name or member record.** There's no member slice; `memberId` is a free string.
- **No author**, no `lentAt`, no overdue flag. Compare `due_on` with today in the screen if needed, or use the "Overdue loans to remind" view once it's built.
- **No "unknown member" error.** An unknown id just returns `[]`.
- **No history.** Returned loans drop out.
