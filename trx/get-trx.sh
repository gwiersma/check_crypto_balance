#!/bin/bash

# Bestand met de lijst van TRON-adressen
input_file="tron_addresses.txt"

# Uitvoer CSV-bestand
output_file="tron_wallet_balances.csv"

if [ ! -f $output_file ]; then
    # Schrijf de header naar het CSV-bestand
	echo "Address,Balance" > "$output_file"
fi

# TRONGrid API URL
api_url="https://api.trongrid.io/v1/accounts/"

# Loop door elk adres in het tekstbestand
while IFS= read -r address
do
  # Verwijder eventuele witruimte of speciale tekens rondom het adres
  address=$(echo "$address" | tr -d '[:space:]')

  # Controleer of het adres niet leeg is
  if [[ -n "$address" ]]; then
    # Voer curl uit om de balans van het adres op te halen via de TRONGrid API
    response=$(curl -sSL "${api_url}${address}")
    sleep 0.5

    # Controleer of de curl-aanroep succesvol was
    if [[ $? -eq 0 ]]; then
      # Haal de balance uit de JSON-response (in SUN, waar 1 TRX = 1,000,000 SUN)
      balance=$(echo "$response" | jq -r '.data[0].balance')

      # Controleer of de balans geldig is
      if [[ "$balance" != "null" ]]; then
        # SUN naar TRX omrekenen
        balance_in_trx=$(echo "scale=6; $balance / 1000000" | bc)

        # Schrijf het adres en de balans naar het CSV-bestand
        echo "$address,$balance_in_trx" >> "$output_file"
    
       elif [[ "$balance" = "null" ]]; then
            echo "Balance is null"

      else
        echo "Fout bij het ophalen van data voor $address (mogelijk ongeldig adres)"
      fi
    else
      echo "Fout bij het ophalen van gegevens van de API voor $address"
    fi
  fi

done < "$input_file"

echo "Gegevens succesvol opgeslagen in $output_file"
