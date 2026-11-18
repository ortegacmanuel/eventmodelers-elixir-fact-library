defmodule Library.Slices.SendReminder.ProcessorTest do
  use ExUnit.Case, async: true

  @moduletag :extra

  alias Library.Slices.SendReminder.Processor

  test "the launch decision: one loan at a time, never the same loan twice" do
    ref = make_ref()

    assert Processor.room_for?(%{}, "l1")
    refute Processor.room_for?(%{ref => "l1"}, "l2")
    refute Processor.room_for?(%{ref => "l1"}, "l1")
    assert Processor.room_for?(Map.delete(%{ref => "l1"}, ref), "l2")
  end
end
