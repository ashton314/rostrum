defmodule Rostrum.DateUtils do
  def to_utc(datetime, source_tz) do
    with {:ok, dtz} <- DateTime.from_naive(datetime, source_tz) do
      DateTime.shift_zone(dtz, "UTC")
    end
  end

  def params_to_utc(params_map, keys, tz) do
    keys
    |> Enum.reduce(params_map, fn k, p ->
      with {:ok, dt} <- Map.fetch(p, k),
           {:ok, dtu} <- to_utc(dt, tz) do
        Map.put(p, k, dtu)
      else
        _ -> p
      end
    end)
  end
end
