#!/bin/bash

# Bestand met de lijst van Bitcoin-adressen
input_file=$1

# Uitvoer CSV-bestand
output_file=$2

if [ ! -f $output_file ]; then
    # Schrijf de header naar het CSV-bestand
	echo "Address,Balance" > "$output_file"
fi

# Variabele om adressen te groeperen
batch_size=200
addresses=()

# Functie om de adressen in batches te verwerken
process_batch() {
  # Voeg adressen samen met '|' separator
  address_string=$(IFS='|' ; echo "${addresses[*]}")
  echo $address_string
  # Voer curl uit om de balans voor meerdere adressen tegelijk op te halen
  response=$(curl -sSL "https://blockchain.info/balance?active=$address_string")

  # Verwerk de JSON-response en schrijf resultaten naar het CSV-bestand
  for address in "${addresses[@]}"; do
    balance=$(echo "$response" | jq -r --arg addr "$address" '.[$addr].final_balance')

    # Controleer of de balans geldig is (jq returnt null bij ongeldige input)
    if [[ "$balance" != "null" ]]; then
      # Satoshi naar BTC omrekenen
      balance_in_btc=$(echo "scale=8; $balance / 100000000" | bc)

      # Schrijf het adres en de balans naar het CSV-bestand
      echo "$address,$balance_in_btc" >> "$output_file"
    else
      echo "Fout bij het ophalen van data voor $address (mogelijk ongeldig adres)"
    fi
  done
}

# Loop door elk adres in het tekstbestand
while IFS= read -r address
do
  # Verwijder eventuele witruimte of speciale tekens rondom het adres
  address=$(echo "$address" | tr -d '[:space:]')

  # Voeg adres toe aan de batch als het niet leeg is
  if [[ -n "$address" ]]; then
    addresses+=("$address")
  fi

  # Verwerk batch zodra we 50 adressen hebben verzameld
  if [[ ${#addresses[@]} -eq $batch_size ]]; then
    process_batch
    addresses=()  # Reset de batch
  fi

done < "$input_file"


# Verwerk eventuele overgebleven adressen als de batch minder dan 50 adressen heeft
if [[ ${#addresses[@]} -gt 0 ]]; then
  process_batch
fi

echo "Gegevens succesvol opgeslagen in $output_file"
