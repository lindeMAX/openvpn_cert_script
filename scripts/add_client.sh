#!/bin/sh

LBLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# The working directory
wdir="$(pwd)/.."

echo "${LBLUE}What's the clients name?${NC}"
read client_name

echo "${LBLUE}Which IP should the client get assigned to?${NC}"
echo "${LBLUE}Do only provide the last number (10.8.0.X)!${NC}"
read client_ip

remote_address=$(cat output/openvpn/server/remote_address.txt)

mkdir ${wdir}/output/openvpn/clients/${client_name}

echo "${GREEN}Creating certificate and key...${NC}"

cd ${wdir}/output/openvpn/EasyRSA-3.0.8/

cp ta.key ${wdir}/output/openvpn/clients/${client_name}

cat <<-EOF | ./easyrsa gen-req ${client_name} nopass
${client_name}
EOF

cp pki/private/${client_name}.key ${wdir}/output/openvpn/clients/${client_name}/

cp pki/reqs/${client_name}.req ${wdir}/output/ca/

echo "${GREEN}Signing certificate...${NC}"

cd ${wdir}/output/ca/EasyRSA-3.0.8/

./easyrsa import-req ../${client_name}.req ${client_name}

cat <<-EOF | ./easyrsa sign-req client ${client_name}
yes
EOF

cp pki/issued/${client_name}.crt ${wdir}/output/openvpn/clients/${client_name}/

cp pki/ca.crt ${wdir}/output/openvpn/clients/${client_name}/

echo "${GREEN}Creating config file...${NC}"

# Place in the specified remote address and set proper client name
cat ${wdir}/conf/client.conf | sed "s/remote_address/${remote_address}/g" | sed "s/c_name/${client_name}/g" > ${wdir}/output/openvpn/clients/${client_name}/${client_name}.conf

cd ${wdir}/output/openvpn/clients/${client_name}

# Remove txqueuelen parameter for windows configuration
cat ${client_name}.conf | sed 's/txqueuelen 1000//g' > ${client_name}.ovpn

# Zip compress the client's directory
echo "${GREEN}Creating .zip archive...${NC}"
cd ../
zip ${client_name}.zip -r ${client_name}

echo "${GREEN}Cleaning up...${NC}"
rm -r ${client_name}

# Push route settings to server.conf and ccd
echo "ifconfig-push 10.8.0.${client_ip} 255.255.255.0" >${wdir}/output/openvpn/server/ccd/${client_name}
echo "route 10.8.0.${client_ip} 255.255.255.0" >> ${wdir}/output/openvpn/server/server.conf

echo "${GREEN}DONE!${NC}"
