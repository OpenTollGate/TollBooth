# Navigate to OpenWRT buildroot
cd openwrt

# Build the backend package
make package/custom/tollbooth-backend/compile V=s

# Transfer package to router
scp bin/packages/<arch>/tollbooth-backend_1.0.0-1_<arch>.ipk root@<router_ip>:/tmp/

# SSH into the router and install
ssh root@<router_ip>
opkg update
opkg install lua-cjson
opkg install /tmp/tollbooth-backend_1.0.0-1_<arch>.ipk
