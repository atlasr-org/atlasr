MAPBOX_GL_JS_VERSION=0.43.0

app: install
	elm-make source/client/Main.elm --output public/javascript/application.elm.js

install: install-mapbox-gl-js

uninstall: uninstall-mapbox-gl-js

install-mapbox-gl-js:
	curl -L https://api.tiles.mapbox.com/mapbox-gl-js/v$(MAPBOX_GL_JS_VERSION)/mapbox-gl.js > public/javascript/mapbox-gl.$(MAPBOX_GL_JS_VERSION).js
	curl -L https://api.tiles.mapbox.com/mapbox-gl-js/v$(MAPBOX_GL_JS_VERSION)/mapbox-gl.css > public/css/mapbox-gl.$(MAPBOX_GL_JS_VERSION).css

uninstall-mapbox-gl-js:
	rm public/javascript/mapbox-gl.$(MAPBOX_GL_JS_VERSION).js
	rm public/css/mapbox-gl.$(MAPBOX_GL_JS_VERSION).css

clean: uninstall
