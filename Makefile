include $(TOPDIR)/rules.mk

PKG_NAME:=tollbooth
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Captive Portals
  TITLE:=Tollbooth
  DEPENDS:=+uhttpd +uhttpd-mod-lua +lua +lua-cjson
endef

define Package/$(PKG_NAME)/description
  Backend plugin providing API endpoints for the captive portal.
endef

define Build/Prepare
  mkdir -p $(PKG_BUILD_DIR)
  cp -r ./files/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
  # Nothing to compile
endef

define Package/$(PKG_NAME)/install
  $(INSTALL_DIR) $(1)/usr/lib/lua/tollbooth
  $(INSTALL_BIN) $(PKG_BUILD_DIR)/usr/lib/lua/tollbooth/*.lua $(1)/usr/lib/lua/tollbooth/

  # (Optional) Install init script
  # $(INSTALL_DIR) $(1)/etc/init.d
  # $(INSTALL_BIN) $(PKG_BUILD_DIR)/etc/init.d/tollbooth-backend $(1)/etc/init.d/tollbooth-backend
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh

# Ensure the 'main' uhttpd section exists
if ! uci get uhttpd.main > /dev/null 2>&1; then
    uci set uhttpd.main=uhttpd
fi

# Set the listening addresses and ports
uci set uhttpd.main.listen_http='0.0.0.0:80'
uci set uhttpd.main.listen_https='0.0.0.0:443'

# Set the document root
uci set uhttpd.main.home='/www'

# Set the index page
uci set uhttpd.main.index_page='index.html'

# Set MIME types
uci set uhttpd.main.mime_type='.html=text/html'
uci add_list uhttpd.main.mime_type='.css=text/css'
uci add_list uhttpd.main.mime_type='.js=application/javascript'
uci add_list uhttpd.main.mime_type='.json=application/json'

# Set CGI prefix
uci set uhttpd.main.cgi_prefix='/cgi-bin'

# Set SSL certificate and key
uci set uhttpd.main.cert='/etc/uhttpd.crt'
uci set uhttpd.main.key='/etc/uhttpd.key'

# Configure Lua handlers
# Remove existing lua_prefix and lua_handler to avoid conflicts
uci delete uhttpd.main.lua_prefix
uci delete uhttpd.main.lua_handler

# Add lua_prefix and lua_handler for '/api/'
uci add_list uhttpd.main.lua_prefix='/api/'
uci set uhttpd.main.lua_handler='/usr/lib/lua/tollbooth/handler.lua'

# Add lua_prefix and lua_handler for '/'
uci add_list uhttpd. .lua_prefix='/'
uci add_list uhttpd.main.lua_handler='/www/tollbooth/router.lua'

# Commit changes
uci commit uhttpd

# Restart uHTTPd to apply changes
/etc/init.d/uhttpd restart

exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh

# Remove the lua_prefix and lua_handler added by the plugin
uci delete uhttpd.main.lua_prefix
uci delete uhttpd.main.lua_handler

# Commit changes
uci commit uhttpd

# Restart uHTTPd to apply changes
/etc/init.d/uhttpd restart

exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
