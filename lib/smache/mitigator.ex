defmodule Smache.Mitigator do
  @moduledoc """
  The Smache.Mitigator module is essentially the brain of the distributed nature of smache
  It figures out where the data lives and then grabs or updates the data
  """

  alias Smache.Normalizer, as: Normalizer

  def put_or_post(key, data) do
    dig(workers(), key, data)
  end

  def get_data(key) do
    dig(workers(), key)
  end

  defp workers() do
    ([Node.self()] ++ Node.list()) |> Enum.sort()
  end

  def get(key) do
    case :ets.lookup(:smache_cache, key) do
      [] ->
        {Node.self(), nil}

      [{_key, data}] ->
        {Node.self(), data}
    end
  end

  defp dig(nodes, key) do
    delegator = mitigate(nodes, key)

    case delegator == Node.self() do
      true ->
        get(key)

      false ->
        distributed_get(delegator, [key])
    end
  end

  defp dig(nodes, key, data) do
    delegator = mitigate(nodes, key)

    case delegator == Node.self() do
      true ->
        Smache.Cache.put_or_post(key, data)

      false ->
        distributed_put_or_post(delegator, [key, data])
    end
  end

  defp mitigate(nodes, key) do
    ukey = Normalizer.normalize(key)

    index = rem(ukey, length(nodes))

    delegator = Enum.at(nodes, index)

    delegator
  end

  defp rand_robin() do
    :"operator_#{:rand.uniform(16)}"
  end

  defp distributed_put_or_post(delegator, args) do
    [key, data] = args

    GenServer.call({rand_robin(), delegator}, {:put_or_post, {key, data}})
  end

  defp distributed_get(delegator, args) do
    [key] = args

    GenServer.call({rand_robin(), delegator}, {:get, {key}})
  end

  ############################################################
  ########################### Please only use this for testing
  ############################################################

  def populate() do
    records =
      1..10_000
      |> Enum.map(fn key ->
        %{key: key, color: "some random color"}
      end)

    records
    |> Enum.map(fn record ->
      put_or_post(record[:key], record)
    end)

    records
    |> Enum.each(fn record ->
      {_node, _data} = get_data(record[:key])
    end)
  end

  def bench do
    ok = :timer.tc(fn -> populate() end) |> elem(0)

    IO.puts("10k records written then read in: " <> "#{ok / 1000} " <> "ms")
  end
end
