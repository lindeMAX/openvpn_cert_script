#!/bin/sh

# The working directory
wdir=$(pwd)

# Color codes for the output (ANSI escape codes)
#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# We need so set some variables first

echo "${RED}How do you want to name your certification agency?${NC}"
read ca_name
echo "${RED}How do you want to name your VPN-Server?${NC}"
read server_name
echo "${RED}How many client certificate-key-pairs do you want to create?${NC}"
read num_clients

# Lets create a proper directory structure first

echo "${GREEN}Creating directory Sturcture...${NC}"
mkdir certs
mkdir certs/ca
mkdir certs/openvpn
mkdir certs/openvpn/server
mkdir certs/openvpn/clients


# Get the latest easyrsa files and extract them
echo "${GREEN} ${NC}"
echo "${GREEN}Downloading EasyRSA...${NC}"
wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz

echo "${GREEN}Extracting...${NC}"
tar xvf EasyRSA-3.0.8.tgz

echo "${GREEN}Creating CA and and OpenVPN EasyRSA-Instacne${NC}"
cp -R EasyRSA-3.0.8/ certs/ca/
cp -R EasyRSA-3.0.8/ certs/openvpn/

echo "${GREEN}Cleaning up...${NC}"
rm -r EasyRSA-3.0.8/
rm EasyRSA-3.0.8.tgz

###############################
### Certification Authority ###
###############################

echo "${GREEN}Doing the CA stuff...${NC}"

cd certs/ca/EasyRSA-3.0.8/
cp vars.example vars

## Wait for the user to react
echo "${RED}You will now have to edit the CAs variables. Press Enter to continue.${NC}"
read ""
nvim vars

## Create the authority
echo "${GREEN}Creating the certification authority...${NC}"
./easyrsa init-pki
echo "${RED}You can leave the 'Common Name' empty${NC}"
cat <<-EOF | ./easyrsa build-ca nopass
${ca_name}
EOF

##################################
### Server Certificate and Key ###
##################################

echo "${GREEN}Creating Server Certificate and Key...${NC}"

cd ${wdir}/certs/openvpn/EasyRSA-3.0.8/

./easyrsa init-pki
cat <<-EOF | ./easyrsa gen-req server nopass
${server_name}
EOF

cp pki/private/server.key ../server/
cp pki/reqs/server.req ${wdir}/certs/ca/

### Sign the server.req on the CA
echo "${GREEN}Signing the server certificate with the CA...${NC}"
cd ${wdir}/certs/ca/EasyRSA-3.0.8/
./easyrsa import-req ../server.req server
cat <<-EOF | ./easyrsa sign-req server server
yes
EOF

### Copy the signed server certificate and the ca.crt back to the server directoy
echo "${GREEN}Copying the signed server certificate back to the server directory...${NC}"
cp pki/issued/server.crt ${wdir}/certs/openvpn/server/ 
cp pki/ca.crt ${wdir}/certs/openvpn/server/
cp pki/ca.crt ${wdir}/certs/openvpn/clients/

cd ${wdir}/certs/openvpn/EasyRSA-3.0.8/

echo "${GREEN}Generating Diffie-Hellman key...${NC}"
./easyrsa gen-dh
cp pki/dh.pem ${wdir}/certs/openvpn/server/

echo "${GREEN}Generating HMAC-Signatur..."
sudo openvpn --genkey secret ta.key
sudo chown ${USER} ta.key
cp ta.key ${wdir}/certs/openvpn/server/
cp ta.key ${wdir}/certs/openvpn/clients/

####################################
### Client Certificates and Keys ###
####################################

echo "${GREEN}Generating client certificates and keys..."

### Create num_clients client certificates
for i in $(seq 1 ${num_clients})
do
    echo "${GREEN}Client ${i}${NC}"
    mkdir ${wdir}/certs/openvpn/clients/client${i}
    cd ${wdir}/certs/openvpn/EasyRSA-3.0.8/
    cat <<-EOF | ./easyrsa gen-req client${i} nopass
    client${i}
EOF
    cp pki/private/client${i}.key ${wdir}/certs/openvpn/clients/client${i}/
    cp pki/reqs/client${i}.req ${wdir}/certs/ca/
    cd ${wdir}/certs/ca/EasyRSA-3.0.8/
    ./easyrsa import-req ../client${i}.req client${i}
    cat <<-EOF | ./easyrsa sign-req client client${i}
    yes
EOF
    cp pki/issued/client${i}.crt ${wdir}/certs/openvpn/clients/client${i}/
done

##############################
### Script for new clients ###
##############################

cd ${wdir}/certs/

cat > add_client <<-EOF
echo "${GREEN}What's the clients name?${NC}"
read client_name
mkdir openvpn/clients/c_name/
cd openvpn/EasyRSA-3.0.8/
./easyrsa gen-req c_name nopass
cp pki/reqs/c_name.req ../../ca/
cp pki/private/c_name.key ../clients/c_name/
cd ../../ca/EasyRSA-3.0.8/
./easyrsa import-req ../c_name.req c_name
./easyrsa sign-req client c_name
cp pki/issued/c_name.crt ../../openvpn/clients/c_name/
EOF

sed 's/c_name/${client_name}/g' add_client > add_client.sh
rm add_client
chmod +x add_client.sh

echo "${GREEN}Done!${NC}"
