#!/bin/bash

# Bestand met de lijst van Bitcoin-adressen
address=$1


# Functie om de adressen in batches te verwerken
process_batch() {
  # Voeg adressen samen met '|' separator
  # Voer curl uit om de balans voor meerdere adressen tegelijk op te halen
  response=$(curl -sSL "https://blockchain.info/balance?active=$address")

  balance=$(echo "$response" | jq -r --arg addr "$address" '.[$addr].final_balance')

  # Controleer of de balans geldig is (jq returnt null bij ongeldige input)
  if [[ "$balance" != "null" ]]; then
    # Satoshi naar BTC omrekenen
    balance_in_btc=$(echo "scale=8; $balance / 100000000" | bc)

    # Schrijf het adres en de balans naar het CSV-bestand
    echo "$balance_in_btc"
  else
    echo "Fout bij het ophalen van data voor $address (mogelijk ongeldig adres)"
    fi

}

# Verwerk eventuele overgebleven adressen als de batch minder dan 50 adressen heeft
if [[ ${#address[@]} -gt 0 ]]; then
  process_batch
fi
