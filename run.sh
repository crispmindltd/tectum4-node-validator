#! /bin/bash
echo "seed phrase:$SEED_PHRASE" > /app/keys/$FILENAME
echo "public key:$PUBLIC_KEY" >> /app/keys/$FILENAME
echo "private key:$PRIVATE_KEY" >> /app/keys/$FILENAME
echo "address:$ADDRESS" >> /app/keys/$FILENAME

exec /app/lnodeconsole