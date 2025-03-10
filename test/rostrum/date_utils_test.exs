defmodule Rostrum.DateUtilsTest do
  use ExUnit.Case
  alias Rostrum.DateUtils

  describe "to_utc/2" do
    test "converts naive datetime to UTC correctly" do
      naive_datetime = ~N[2023-10-10 12:00:00]
      timezone = "America/New_York"

      # 12:00 PM EDT => 04:00 PM UTC
      assert {:ok, dt} = DateUtils.to_utc(naive_datetime, timezone)
      assert DateTime.diff(dt, ~U[2023-10-10 16:00:00.00+00:00]) == 0
    end

    test "returns error for invalid timezone" do
      naive_datetime = ~N[2023-10-10 12:00:00]
      timezone = "Invalid/Timezone"

      assert DateUtils.to_utc(naive_datetime, timezone) == {:error, :time_zone_not_found}
    end
  end

  describe "params_to_utc/2" do
    test "basic conversion" do
      params = %{foo: ~N[2025-10-10 12:00:00], bar: ~N[2025-10-10 13:00:00]}

      new_params = DateUtils.params_to_utc(params, [:foo, :bar], "America/New_York")
      assert DateTime.diff(new_params.foo, ~U[2025-10-10 16:00:00Z]) == 0
      assert DateTime.diff(new_params.bar, ~U[2025-10-10 17:00:00Z]) == 0
    end

    test "some keys" do
      params = %{foo: ~N[2025-10-10 12:00:00], bar: ~N[2025-10-10 13:00:00]}

      new_params = DateUtils.params_to_utc(params, [:foo], "America/New_York")
      assert DateTime.diff(new_params.foo, ~U[2025-10-10 16:00:00Z]) == 0
      assert new_params.bar == ~N[2025-10-10 13:00:00]
    end

    test "keys missing/nil" do
      params = %{foo: ~N[2025-10-10 12:00:00], bar: ~N[2025-10-10 13:00:00]}

      new_params = DateUtils.params_to_utc(params, [:foo, :baz], "America/New_York")
      assert DateTime.diff(new_params.foo, ~U[2025-10-10 16:00:00Z]) == 0
      assert new_params.bar == ~N[2025-10-10 13:00:00]
    end
  end
end
