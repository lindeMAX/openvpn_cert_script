#!/bin/sh

LBLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# The working directory
wdir=$(pwd)

# We need so set some variables first

echo "${LBLUE}How do you want to name your certification agency?${NC}"
read ca_name
echo "${LBLUE}How do you want to name your VPN-Server?${NC}"
read server_name
echo "${LBLUE}What's the server's remote address?${NC}"
read remote_address
echo "${LBLUE}How many client certificate-key-pairs do you want to create?${NC}"
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
echo "${LBLUE}You will now have to edit the CAs variables. Press Enter to continue.${NC}"
read ""
editor vars

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
cp pki/issued/server.crt ${wdir}/certs/openvpn/server/ 
cp pki/ca.crt ${wdir}/certs/openvpn/server/

cd ${wdir}/certs/openvpn/EasyRSA-3.0.8/

echo "${GREEN}Generating Diffie-Hellman key...${NC}"
./easyrsa gen-dh
cp pki/dh.pem ${wdir}/certs/openvpn/server/

echo "${GREEN}Generating HMAC-Signatur...${NC}"
sudo openvpn --genkey secret ta.key
sudo chown ${USER} ta.key
cp ta.key ${wdir}/certs/openvpn/server/

cp ${wdir}/server.conf ${wdir}/certs/openvpn/server/server.conf

# Create client config directory
mkdir ${wdir}/certs/openvpn/server/ccd

####################################
### Client Certificates and Keys ###
####################################

echo "${GREEN}Generating client certificates and keys..."

### Create 'num_clients' client certificates
for i in $(seq 1 ${num_clients})
do
   echo "${GREEN}Client ${i}:${NC}"
   mkdir ${wdir}/certs/openvpn/clients/client${i}
   echo "${GREEN}Creating certificate and key...${NC}"
   cd ${wdir}/certs/openvpn/EasyRSA-3.0.8/
   cp ta.key ${wdir}/certs/openvpn/clients/client${i}
   cat <<-EOF | ./easyrsa gen-req client${i} nopass
   client${i}
EOF
   echo "${GREEN}Signing certificate...${NC}"
   cp pki/private/client${i}.key ${wdir}/certs/openvpn/clients/client${i}/
   cp pki/reqs/client${i}.req ${wdir}/certs/ca/
   cd ${wdir}/certs/ca/EasyRSA-3.0.8/
   ./easyrsa import-req ../client${i}.req client${i}
   cat <<-EOF | ./easyrsa sign-req client client${i}
   yes
EOF
   cp pki/issued/client${i}.crt ${wdir}/certs/openvpn/clients/client${i}/
   cp pki/ca.crt ${wdir}/certs/openvpn/clients/client${i}/
   # Place in the specified remote address and set proper client name
   echo "${GREEN}Creating config file...${NC}"
   cat ${wdir}/client.conf | sed "s/remote_address/${remote_address}/g" | sed "s/c_name/client${i}/g" > ${wdir}/certs/openvpn/clients/client${i}/client${i}.conf
   cd ${wdir}/certs/openvpn/clients/client${i}
   # Remove txqueuelen parameter for windows configuration
   cat client${i}.conf | sed 's/txqueuelen 1000//g' > client${i}.ovpn
   # Zip compress the client's directory
   echo "${GREEN}Creating .zip archive...${NC}"
   cd ../
   zip client${i}.zip -r client${i}
   echo "${GREEN}Cleaning up...${NC}"
   rm -r client${i}
   # Push route settings to server.conf and ccd
   ip=$(expr 100 + ${i})
   echo "ifconfig-push 10.8.0.${ip} 255.255.255.0" >${wdir}/certs/openvpn/server/ccd/client${i}
   echo "route 10.8.0.${ip} 255.255.255.0" >> ${wdir}/certs/openvpn/server/server.conf
done

echo "${GREEN}DONE!${NC}"