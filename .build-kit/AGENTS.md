<!-- Generated from the slice-state event log. Record learnings with the learn command; do not edit. -->

## The framework
- `lib/library/`: `decide.ex`, `reader.ex`, `state_change.ex`, `state_view.ex`, `event.ex`, `command.ex`. **Don't touch them** unless asked.
- `Decide` waits until the write is visible before returning: `Fact.append/3` confirms 7–10 ms before a subsequent read can see it. Without that wait, a LiveView that writes and immediately repaints shows the old state.
- `Reader.read/2` reads by index instead of scanning the ledger. Measured: a tag query over 20,000 events, **235 ms scanning vs 0.07 ms by index**. It matters because every write starts with a read.
- Known ceiling, deliberately **not** solved in the base framework: with the append condition anchored at 0 — which is what happens when the fold finds nothing — FACT scans the entire ledger. Measured: 29 ms at 531 events, **4.5 s at 157,711**. The fix is anchoring on a visibility mark; the seam is documented in `Decide.read_and_fold/3`.

## About `slice.json`
- **`tags: []` doesn't mean "no tags", it means "underived".** They come from the fields with `idAttribute: true`. It's the most important rule in the kit.
- **The `slice.json` the loop writes is a stub.** `fetchAndPersistSlices` uses the **summary** endpoint: six fields, ~230 bytes, no `fields`, no `events`, no `specifications`, and **no board comments**. Refresh with `npx @eventmodelers/cli fetch --context <ctx>` — it's step 0 in `CLAUDE.md`.
- This happened for real, and the first time it worked **by luck**: for slices with ASCII titles the stub **overwrote** the full definition, and only the ones with accents or `·` survived, because they landed in a different folder.
- The canonical folder name is `title` with spaces removed, lowercased, **keeping accents and `·`**. Normalising to ASCII creates a parallel folder the loop never looks at.
- The screen arrives as metadata: `title`, `fields`, `dependencies` and prose. **The rendered design does not travel in the payload.**
- Each node's `description` carries the invariants written out in prose, and often explains **which rules were removed and why**. It's the most valuable thing in the file and the easiest to skip.
- The scenarios' `examples` are often **measured against real systems**. If a test fails, suspect the test before the data.

## FACT and quality-gate traps
- **`event_data` comes back with string keys in snake_case.** Events are serialised with `Map.from_struct/1`, so a `checkId` on the board reads as `d["check_id"]`. You can confirm by looking at the files under `data/fact_db/events/<xx>/<id>` — they're plain JSON.
- **The store must exist before boot.** If it doesn't, `Application.fact_db/0` **raises** after two seconds and takes down whatever the user was doing. That's why `fact.setup` is in the aliases for `test`, `setup` **and** `phx.server`.
- **`mix precommit` compiles with `--warnings-as-errors`.** A `defp f(x, y \\ %{})` whose default is never used is a warning, and it fails the gate.

## About tests
- **Never compare `Map.keys/1` against a list.** The order isn't guaranteed: `assert Map.keys(row) == [:a, :b, :c]` fails **intermittently** — it passes locally and breaks the gate later. It got committed that way once. Use `MapSet`.
- A passing test can be lying. One asserted that a button starts disabled — true only because there's no JavaScript in tests to publish the initial state. **When a test depends on something the browser does on its own, simulate it explicitly.**
- `Application.put_env` is global. A test that mutates it **can't live in an `async: true` module** alongside another that reads the same config.
- With `nil`, HEEx **omits the attribute entirely** rather than rendering it empty, so the obvious assertion (`data-x=''`) matches nothing.

## About read slices
- **A TODO queue isn't scoped by tag.** It's the exception to "the tag scopes the view": its consumer is a processor, which has no session or any other identity to filter by. The query goes by types.
- **The expensive failure is a type missing from `query/1`.** It doesn't blow up: it leaves the field `nil` forever and nobody notices. Worth a test on `query/1` itself — the types and the tags — because the rest of the suite passes just the same with a wrong query.
- **A queue with no status field is a decision, not an oversight.** Membership of the list *is* the status.

## About claiming slices
- The loop rejects the status change if the slice is already in the target status: **that's not an error**, it means another agent claimed it first. Don't retry that slice; move to the next `Planned` one in the current context.
- Two loops on the same directory share `progress.txt`, `index.json` and the working tree, and each wants its own branch in the same checkout. If you run them in parallel, **one worktree per agent**.
- An idle loop may not notice a slice marked `Planned` if the realtime event doesn't arrive. Refreshing the local index unblocks it.

## The screen brief
- If the slice has `screens`, alongside the domain you write `docs/screens/<slice>.md`. Template and rules in `.build-kit/CLAUDE.md`.
- **The section that earns its keep is "What the domain does NOT give you".** It's what stops whoever builds the view from inventing fields or asking the domain for them without cause. Write it even if the rest ends up short.
- The **error atoms** from `Core` always go in: the screen translates them into messages and can't guess them from `slice.json`.
- It lives in `docs/` and not `.build-kit/` on purpose: `.build-kit/` is regenerated on every fetch and the brief has to survive.

## About automation slices
- An automation reads its TODO queue through `<Queue>.Context.pending/0` (the kit's convention; the queue's Context reads the clock itself). When the queue slice isn't built yet, build against that name anyway (request-feedback forbids blocking on an unbuilt dependency): hold the queue module as a value in the processor state (Keyword.get(opts, :queue, Queue)) so compile --warnings-as-errors stays green; the poll's rescue logs the UndefinedFunctionError until the queue exists, and test/library/automation_queue_test.exs checks both agree once it does.
- An automation with no external system (just records our own fact) still runs its sweep in a Task under Library.TaskSupervisor, one sweep in flight (room_for?/1 tested under @moduletag :extra). The sweep returns :done on an empty queue so a success doesn't chain into itself.

## About write slices
- A decision spanning two consistency boundaries (e.g. book and member) is one DCB read: query/1 returns a list of Fact.QueryItem (OR-ed by Reader), each scoped by its own tag; append_condition follows. apply_event doesn't see the command, so fold keyed by the event's own id (e.g. open loans by loan_id) and filter by the command's ids inside execute/2.
- A command naming one id (e.g. bookId) whose event needs others (loanId, memberId): fold them from the history in Core and copy them into the event — the command keeps only the board's fields. Two SPEC_ERROR scenarios with the same board code are one atom and one execute clause.

## Slice layout
- Slice folder/module name = title NFD-stripped, downcased, every non-alnum run -> '_' ("Member's loans" -> member_s_loans, MemberSLoans). scenario_tests_test.exs silently skips test dirs with any other name.

## Read slices
- A view scoped by one tag that needs fields from events carrying only another tag (title on book:-tagged events, view by member:): fold the ids, then next_query/1 returns one QueryItem per id.
- Date fields come back from FACT as ISO strings; a view that compares dates parses them with Date.from_iso8601!/1 in apply_event and takes the reference date (today) as the read argument, filtering in project/2 — never Date.utc_today() in Core.
