#!/bin/bash

# Bestand met de lijst van Bitcoin-adressen
input_file="cluster_addresses.txt"

# Uitvoer CSV-bestand
output_file="Check_BTC_Multisig.csv"

if [ ! -f $output_file ]; then
    # Schrijf de header naar het CSV-bestand
	echo "Address,Multisig" > "$output_file"
fi


# Loop door elk adres in het tekstbestand
while IFS= read -r address
do
  # Verwijder eventuele witruimte of speciale tekens rondom het adres
  address=$(echo "$address" | tr -d '[:space:]')

  # Controleer of het adres niet leeg is
  if [[ -n "$address" ]]; then
    # Voer curl uit en gebruik jq om het finale saldo te extraheren
    multisig=$(curl -sSL "https://mempool.space/api/address/$address/txs/chain | jq '.[] | .vin[] | .inner_redeemscript_asm'") 

    # Controleer of de balans geldig is (jq returnt null bij ongeldige input)
    if [[ "$" != "null" ]]; then
      # Check of er OP_CHECKMULTISIG in de tekst staat
      if [[ $multisig == *"OP_CHECKMULTISIG"* ]]; then
          echo "$address,'True'" >> "$output_file"
    else
      echo "Fout bij het ophalen van data voor $address (mogelijk ongeldig adres)"
    fi
  fi

done < "$input_file"

echo "Gegevens succesvol opgeslagen in $output_file"
