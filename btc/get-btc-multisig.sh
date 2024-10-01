#!/bin/bash

# Bestand met de lijst van Bitcoin-adressen
input_file="cluster_addresses.txt"

# Uitvoer CSV-bestand
output_file="CheckCluster_BTC_Multisig.csv"

# Rate limit delay (250 req per min)
delay=4

if [ ! -f $output_file ]; then
    # Schrijf de header naar het CSV-bestand
	echo "Address,Multisig,Balance" > "$output_file"
fi


# Loop door elk adres in het tekstbestand
while IFS= read -r address
do
  # Verwijder eventuele witruimte of speciale tekens rondom het adres
  address=$(echo "$address" | tr -d '[:space:]')
  echo $address
  # Controleer of het adres niet leeg is
  if [[ -n "$address" ]]; then
    # Voer curl uit en gebruik jq om het finale saldo te extraheren
    multisig=$(curl -sSL "https://mempool.space/api/address/$address/txs/chain" | jq '.[] | .vin[] | .inner_redeemscript_asm') 
    balance=$(bash func_get_btc_balance.sh $address)
    # Controleer of de balans geldig is (jq returnt null bij ongeldige input)
    if [[ "$multisig" != "null" ]]; then
      # Check of er OP_CHECKMULTISIG in de tekst staat
      if [[ $multisig == *"OP_CHECKMULTISIG"* ]]; then
          echo "$address,True,$balance" >> "$output_file"

      elif [[ $multisig != *"OP_CHECKMULTISIG"* ]]; then
          echo "$address,False,$balance" >> "$output_file"
      fi

    else
      echo "Fout bij het ophalen van data voor $address (mogelijk ongeldig adres),Unkown,$balance" >> "$output_file"
    fi
    # Voeg een vertraging van 0.24 seconden in na elke request
    sleep $delay
  fi

done < "$input_file"

echo "Gegevens succesvol opgeslagen in $output_file"
