MAPBOX_GL_JS_VERSION=0.43.0

install: install-client install-mapbox-gl-js
uninstall: uninstall-client uninstall-client-dependencies

open: install
	open public/index.html

clean: uninstall
.PHONY: clean

###
# Client
###

install-client: public/javascript/application.elm.js install-client-dependencies
public/javascript/application.elm.js:
	elm-make source/client/Main.elm --output public/javascript/application.elm.js

uninstall-client:
	rm public/javascript/application.elm.js

###
# Client dependencies
###

install-client-dependencies: install-mapbox-gl-js
uninstall-client-dependencies: uninstall-mapbox-gl-js

###
# Client dependencies: Mapbox GL JS
###

install-mapbox-gl-js: install-mapbox-gl-js-js install-mapbox-gl-js-css

install-mapbox-gl-js-js: public/javascript/mapbox-gl.js public/javascript/mapbox-gl.js.map
public/javascript/mapbox-gl.js:
	curl -L https://api.tiles.mapbox.com/mapbox-gl-js/v$(MAPBOX_GL_JS_VERSION)/mapbox-gl.js > public/javascript/mapbox-gl.js
public/javascript/mapbox-gl.js.map:
	curl -L https://api.tiles.mapbox.com/mapbox-gl-js/v$(MAPBOX_GL_JS_VERSION)/mapbox-gl.js.map > public/javascript/mapbox-gl.js.map

install-mapbox-gl-js-css: public/css/mapbox-gl.css
public/css/mapbox-gl.css:
	curl -L https://api.tiles.mapbox.com/mapbox-gl-js/v$(MAPBOX_GL_JS_VERSION)/mapbox-gl.css > public/css/mapbox-gl.css

uninstall-mapbox-gl-js:
	rm public/javascript/mapbox-gl.js
	rm public/javascript/mapbox-gl.js.map
	rm public/css/mapbox-gl.css
