```sh
certbot certonly \
	--config-dir ~/.config/certbot \
	--logs-dir ~/.cache/certbot \
	--work-dir ~/.cache/certbot \
	-v \
	-d rekry.tietokilta.fi \
	--manual \
	--reuse-key \
	--preferred-challenges dns

openssl pkcs12 \
	-export \
	-legacy \
	-inkey ~/.config/certbot/live/rekry.tietokilta.fi/privkey.pem \
	-in ~/.config/certbot/live/rekry.tietokilta.fi/fullchain.pem \
	-out modules/recruiting/ghost/rekry.tietokilta.fi.pfx
```
