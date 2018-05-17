defmodule Smache.Mitigator do
  alias Smache.Normalizer, as: Normalizer

  def fetch(key, data) do
    dig(workers(), key, data)
  end

  def grab_data(key) do
    dig(workers(), key)
  end

  defp workers() do
    ([Node.self()] ++ Node.list()) |> Enum.sort()
  end

  def data(key) do
    case :ets.lookup(:smache_cache, key) do
      [] ->
        {Node.self(), nil}

      [{_key, data}] ->
        {Node.self(), data}
    end
  end

  defp dig(nodes, key) do
    {index, delegator} = mitigate(nodes, key)

    case delegator == Node.self() do
      true ->
        data(key)

      false ->
        node_data({delegator, key}, [key])
    end
  end

  defp dig(nodes, key, data) do
    {index, delegator} = mitigate(nodes, key)

    case delegator == Node.self() do
      true ->
        Smache.Ets.Table.fetch(key, data)

      false ->
        node_fetch({delegator, key}, [key, data])
    end
  end

  defp mitigate(nodes, key) do
    ukey = Normalizer.normalize(key)
    index = rem(ukey, length(nodes))
    delegator = Enum.at(nodes, index)

    {index, delegator}
  end

  defp node_fetch(delegator, args) do
    :gen_rpc.call(delegator, Smache.Ets.Table, :fetch, args)
  end

  defp node_data(delegator, args) do
    :gen_rpc.call(delegator, Smache.Mitigator, :data, args)
  end
end
