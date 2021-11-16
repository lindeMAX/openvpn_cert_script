#  #

*create_certs.sh* will create a complete certification infrastructure for you.

- Certification Authority
- Server certificats and keys
- Client certificats and keys

It will ask you for the name of the ca, the vpn-server and how many client certificates/keys you want to create.

In addition to that, another script (*add_client.sh*) will be created to add more clients afterwards (e.g. hugo).

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
    +---server
    |   +---ta.key
    |   +---ca.crt
    |   +---dh.pem
    |   +---server.crt
    |   +---server.key
    |   |
    |   ...
    |
    +---clients
        +--ca.crt
        +--ta.key
        |
        +---client1
        |   +---client1.crt
        |   +---client1.key
        ...
        |---clientXX
        |   +---clientXX.crt
        |   +---clientXX.key
        |
        +---hugo
            +---hugo.crt
            +---hugo.key 
```
