#!/bin/sh

LBLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# The working directory
wdir=$(pwd)

echo "${LBLUE}What's the clients name?${NC}"
read client_name

mkdir ${wdir}/certs/openvpn/clients/${client_name}

echo "${GREEN}Creating certificate and key...${NC}"

cd ${wdir}/certs/openvpn/EasyRSA-3.0.8/

cp ta.key ${wdir}/certs/openvpn/clients/${client_name}

cat <<-EOF | ./easyrsa gen-req ${client_name} nopass
${client_name}
EOF

cp pki/private/${client_name}.key ${wdir}/certs/openvpn/clients/${client_name}/

cp pki/reqs/${client_name}.req ${wdir}/certs/ca/

echo "${GREEN}Signing certificate...${NC}"

cd ${wdir}/certs/ca/EasyRSA-3.0.8/

./easyrsa import-req ../${client_name}.req ${client_name}

cat <<-EOF | ./easyrsa sign-req client ${client_name}
yes
EOF

cp pki/issued/${client_name}.crt ${wdir}/certs/openvpn/clients/${client_name}/

cp pki/ca.crt ${wdir}/certs/openvpn/clients/${client_name}/

echo "${GREEN}Creating config file...${NC}"

# Place in the specified remote address and set proper client name
cat ${wdir}/client.conf | sed "s/remote_address/${remote_address}/g" | sed "s/c_name/${client_name}/g" > ${wdir}/certs/openvpn/clients/${client_name}/${client_name}.conf

cd ${wdir}/certs/openvpn/clients/${client_name}

# Remove txqueuelen parameter for windows configuration
cat ${client_name}.conf | sed 's/txqueuelen 1000//g' > ${client_name}.ovpn

# Zip compress the client's directory
echo "${GREEN}Creating .zip archive...${NC}"
cd ../
zip ${client_name}.zip -r ${client_name}

echo "${GREEN}Cleaning up...${NC}"
rm -r ${client_name}

# Create client config directory
mkdir ${wdir}certs/openvpn/server/ccd/client${i}
# Push route settings to server.conf and ccd
ip=$(expr 100 + ${i})
echo "ifconfig-push 10.8.0.${ip} 255.255.255.0" >${wdir}/certs/openvpn/server/ccd/client${i}
echo "route 10.8.0.${ip} 255.255.255.0" >> ${wdir}certs/openvpn/server/server.conf


echo "${GREEN}DONE!${NC}"
