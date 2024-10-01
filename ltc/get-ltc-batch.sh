#!/bin/bash

# Bestand met de lijst van Litecoin-adressen
input_file="ltc_cluster_addresses.txt"

# Uitvoer CSV-bestand
output_file="ltc_wallet_balances.csv"

if [ ! -f $output_file ]; then
    # Schrijf de header naar het CSV-bestand
	echo "Address,Balance" > "$output_file"
fi

# Loop door elk adres in het tekstbestand
while IFS= read -r address
do
  # Verwijder eventuele witruimte of speciale tekens rondom het adres
  address=$(echo "$address" | tr -d '[:space:]')

  # Controleer of het adres niet leeg is
  if [[ -n "$address" ]]; then

    URL="https://rest.cryptoapis.io/blockchain-data/litecoin/mainnet/addresses/$address/balance?context=yourExampleString"
    # Voer curl uit om de balans van het adres op te halen via de BlockCypher API
    response=$(curl -X GET -H "Content-Type: application/json"  -H "x-api-key: dd8172b9b967cb2c97df3ef9c907b06ea07be4bc"  "$URL")
    sleep 1
    
    # Controleer of de curl-aanroep succesvol was
    if [[ $? -eq 0 ]]; then
      # Haal de confirmed balance uit de JSON-response (in satoshis)
      balance=$(echo "$response" | jq -r '.data.item.confirmedBalance.amount')

      # Controleer of de balans geldig is
      if [[ "$balance" != "null" ]]; then
        # Satoshi naar Litecoin omrekenen
        #balance_in_ltc=$(echo "scale=8; $balance / 100000000" | bc)

        # Schrijf het adres en de balans naar het CSV-bestand
        echo "$address,$balance" >> "$output_file"
      else
        echo "Fout bij het ophalen van data voor $address (mogelijk ongeldig adres)"
      fi
    else
      echo "Fout bij het ophalen van gegevens van de API voor $address"
    fi
  fi

done < "$input_file"

echo "Gegevens succesvol opgeslagen in $output_file"
