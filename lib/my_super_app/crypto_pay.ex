defmodule MySuperApp.Payment do
  @rpc_url "http://127.0.0.1:7545"

  def get_balance(address) do
    address = String.replace_prefix(address, "0x", "")

    payload = %{
      "jsonrpc" => "2.0",
      "method" => "eth_getBalance",
      "params" => ["0x" <> address, "latest"],
      "id" => 1
    }

    case HTTPoison.post(@rpc_url, Jason.encode!(payload), [{"Content-Type", "application/json"}]) do
      {:ok, %{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"result" => hex_balance}} ->
            balance = String.to_integer(String.replace_prefix(hex_balance, "0x", ""), 16) / 1.0e18
            {:ok, balance}

          {:error, _} ->
            {:error, "Failed to decode balance from response"}
        end

      {:error, _reason} ->
        {:error, "Failed to connect to the Ethereum node"}
    end
  end

  def send_transaction(from_address, to_address, amount, private_key) do
    value = "0x" <> Integer.to_string(trunc(amount * 1.0e18), 16)  # convert amount to Wei and to hex

    payload = %{
      "jsonrpc" => "2.0",
      "method" => "eth_sendTransaction",
      "params" => [%{
        "from" => from_address,
        "to" => to_address,
        "value" => value
      }],
      "id" => 1
    }

    case HTTPoison.post(@rpc_url, Jason.encode!(payload), [{"Content-Type", "application/json"}]) do
      {:ok, %{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"result" => tx_hash}} ->
            {:ok, tx_hash}

          {:error, _} ->
            {:error, "Failed to decode transaction hash from response"}
        end

      {:error, _reason} ->
        {:error, "Failed to connect to the Ethereum node"}
    end
  end

  def get_transaction_status(tx_hash) do
    payload = %{
      "jsonrpc" => "2.0",
      "method" => "eth_getTransactionReceipt",
      "params" => [tx_hash],
      "id" => 1
    }

    case HTTPoison.post(@rpc_url, Jason.encode!(payload), [{"Content-Type", "application/json"}]) do
      {:ok, %{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"result" => result}} when not is_nil(result) ->
            status = Map.get(result, "status") == "0x1"
            if status, do: {:ok, "Transaction succeeded"}, else: {:ok, "Transaction failed"}

          {:ok, %{"result" => nil}} ->
            {:ok, "Transaction is pending"}

          {:error, _} ->
            {:error, "Failed to decode transaction status from response"}
        end

      {:error, _reason} ->
        {:error, "Failed to connect to the Ethereum node"}
    end
  end
end
