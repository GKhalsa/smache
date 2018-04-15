{:ok, ifs} = :inet.getif()

name =
  :crypto.hash(:sha256, to_string(:rand.uniform()))
  |> Base.encode16
  |> String.slice(0..10)
  |> String.downcase

ips =
  Enum.map(ifs, fn {ip, _b, _m} ->
    Enum.join(Tuple.to_list(ip), ".")
  end)

ip = ips |> Enum.at(0)

cookie =
  File.read!(".env")
  |> String.split("\n")
  |> Enum.at(1)
  |> String.split("=")
  |> Enum.at(1)

env_vars = [
  "REPLACE_OS_VARS=true",
  "SNAME_IP=#{name}@#{ip}",
  "COOKIE=#{cookie}",
]

env_vars
|> Enum.map(&"export #{&1} ")
|> IO.puts
