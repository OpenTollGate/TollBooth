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
endef

define Package/$(PKG_NAME)/install
  $(INSTALL_DIR) $(1)/usr/lib/lua/tollbooth
  $(INSTALL_BIN) $(PKG_BUILD_DIR)/usr/lib/lua/tollbooth/*.lua $(1)/usr/lib/lua/tollbooth/

endef

define Package/$(PKG_NAME)/postinst

if ! uci get uhttpd.main > /dev/null 2>&1; then
    uci set uhttpd.main=uhttpd
fi

uci set uhttpd.main.listen_http='0.0.0.0:80'
uci set uhttpd.main.listen_https='0.0.0.0:443'

uci set uhttpd.main.home='/www'

uci set uhttpd.main.index_page='index.html'

uci set uhttpd.main.mime_type='.html=text/html'
uci add_list uhttpd.main.mime_type='.css=text/css'
uci add_list uhttpd.main.mime_type='.js=application/javascript'
uci add_list uhttpd.main.mime_type='.json=application/json'

uci set uhttpd.main.cgi_prefix='/cgi-bin'

uci set uhttpd.main.cert='/etc/uhttpd.crt'
uci set uhttpd.main.key='/etc/uhttpd.key'

uci delete uhttpd.main.lua_prefix
uci delete uhttpd.main.lua_handler

uci add_list uhttpd.main.lua_prefix='/api/'
uci set uhttpd.main.lua_handler='/usr/lib/lua/tollbooth/handler.lua'

uci add_list uhttpd. .lua_prefix='/'
uci add_list uhttpd.main.lua_handler='/www/tollbooth/router.lua'

uci commit uhttpd

/etc/init.d/uhttpd restart

exit 0
endef

define Package/$(PKG_NAME)/prerm

uci delete uhttpd.main.lua_prefix
uci delete uhttpd.main.lua_handler

uci commit uhttpd

/etc/init.d/uhttpd restart

exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
