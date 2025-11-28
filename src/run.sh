#! /bin/bash
mkdir /app/keys/
rm -rf /app/keys/*
echo "seed phrase:$SEED_PHRASE" > /app/keys/$FILENAME
echo "public key:$PUBLIC_KEY" >> /app/keys/$FILENAME
echo "private key:$PRIVATE_KEY" >> /app/keys/$FILENAME
echo "address:$ADDRESS" >> /app/keys/$FILENAME
sed -i "s|nodes=\[.*\]|nodes=[$NODES]|g" /app/settings.ini
cat <<EOF >> settings.ini
[miner]
enabled=y
EOF


exec /app/ctectumnode