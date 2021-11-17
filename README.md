# openvpn_cert_script #

*create_certs.sh* creates all certificates and keys needed for openvpn (using EasyRSA v3.0.8) alongside with the config files and directory tree needed on the server and client side.

It will ask you for the name of the ca, the vpn-server, it's remote address and how many client certificates/keys you want to create.
A zip compressed directory is then assambled for each individual client.

```
clientXX.zip
    +---clientXX.crt
    +---clientXX.key
    +---clientXX.conf
    +---client.ovpn
    +---ta.key
    +---ca.crt
```

The server.conf is edited in a way, that each client will get it's own IP-address, beginning with *10.8.0.101*.
Therefore the client config directory (ccd) is created, too.

There is also *add_client.sh* to add more clients afterwards (e.g. hugo).<br>
You can choose a specific IP for each client added individually afterwards.

The directory stucture will look loke this:

```
certs
+---add_client.sh
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

## config files ##

- tap 
- client to client
- mtu of 1492 to work properly over DSL with PPPoE
- ...

Feel free to edit, to suit your needs.

## Dependencies ##
- openvpn