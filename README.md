# Openvpn Setup Script

*openvpn_setup.sh* creates all certificates and keys needed for [openvpn](https://openvpn.net/) (using EasyRSA v3.0.8) alongside with the config files and directory tree needed on the server and client side.

It will ask you for the name of the ca, the vpn-server, it's remote address and how many client certificates/keys you want to create.
A zip compressed directory is then assambled for each individual client.

```
clientXX.zip
    +---clientXX.crt
    +---clientXX.key
    +---clientXX.conf
    +---clientXX.ovpn
    +---ta.key
    +---ca.crt
```

The server.conf is edited in a way, that each client will get it's own IP-address, beginning with *10.8.0.101*.
Therefore the client config directory (ccd) is created, too.

There is also *add_client.sh* to add more clients afterwards (e.g. hugo).<br>
You can choose a specific IP for each client added afterwards individually.

The directory stucture will look like this:

```
output
|
+---ca
|   +---...
|   ...
|
+---openvpn
    |
    +...
    |
    +---server
    |   +---ta.key
    |   +---ca.crt
    |   +---dh.pem
    |   +---server.crt
    |   +---server.key
    |   +---server.conf
    |   |
    |   +---ccd/
    |
    +---clients
        |
        +---client1.zip
        ...
        +---clientXX.zip
        +---hugo.zip
```

## Dependencies ##

- zip
- unzip
- zsh
- openvpn (2.5.1-3)

## config files ##

Feel free to edit to make it suit your needs.
This [openvpn how to](https://openvpn.net/community-resources/how-to/) could come in handy ;)
<br>
**Important:** One should do this before running the script.

## Using the scripts

```Bash
cd scripts
./openvpn_setup.sh
./add_client.sh
```

## Executing the Openvpn Server ##

### Manually 

```Bash
cd <path_to_output>/openvpn/server
sudo openvpn sserver.conf
```

### As Systemd Service

Just copy *output/openvpn/server* to */etc/openvpn/* and start the systemd service:

```Bash
systemctl enable openvpn-server@server.service
systemctl start openvpn-server@server.service
```

Where *...@server...* specifies the used configuration file/directory.

## Executing a Client ##

Similar to the server.
<br>
At least on linux.
