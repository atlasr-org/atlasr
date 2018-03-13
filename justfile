mapbox_gl_js_version = "0.44.1"

# Open Atlasr in your favorite browser.
open: install
	open http://127.0.0.1:8889

# Install Atlasr!
install: install-server install-api install-client

# Uninstall Atlasr.
uninstall: uninstall-server uninstall-api uninstall-client

# Install the HTTP server.
install-server:
	cd source/server && cargo build --release

# Uninstall the HTTP server.
uninstall-server:
	rm -rf source/server/Cargo.lock source/server/target

# Run the HTTP server (will not exit).
run-server: install
	cd source/server && cargo run

# Install all the APIs.
install-api: install-api-graphhopper

# Uninstall all the APIs.
uninstall-api: uninstall-api-graphhopper

# Install GraphHopper.
install-api-graphhopper:
	git submodule update --init source/api/graphhopper

# Uninstall GraphHopper.
uninstall-api-graphhopper:
	# noop

# Run GraphHopper for a particular PBF zone.
run-api-graphhopper map_file='europe_switzerland': install-api-graphhopper
	source/api/graphhopper/graphhopper.sh web {{map_file}}.pbf

# Install client.
install-client: install-client-index install-client-application install-client-dependencies

# Uninstall client.
uninstall-client: uninstall-client-index uninstall-client-application

# Create a public `index.html` file.
install-client-index:
	cp source/client/index.html public/static/index.html
	sed -i '' "s@{MAP-PLACEHOLDER.svg}@`cat public/static/image/map-placeholder.svg | sed -E 's/^ +//g; s/"/'"'"'/g; s/</%3c/g; s/>/%3e/g; s/\#/%23/g' | tr -d "\n"`@" public/static/index.html

# Remove the public `index.html` file.
uninstall-client-index:
	rm -f public/static/index.html

# Compile the Elm application to JS.
install-client-application:
	elm-make source/client/Main.elm --output public/static/javascript/application.elm.js

# Remove the Elm build artifact.
uninstall-client-application:
	rm -f public/static/javascript/application.elm.js

# Install client dependencies.
install-client-dependencies: install-mapbox-gl-js

# Uninstall client dependencies.
uninstall-client-dependencies: uninstall-mapbox-gl-js

# Install Mapbox GL JS, so JS, CSS and SourceMap.
install-mapbox-gl-js:
	curl -L https://api.tiles.mapbox.com/mapbox-gl-js/v{{mapbox_gl_js_version}}/mapbox-gl.js > public/static/javascript/mapbox-gl.js
	curl -L https://api.tiles.mapbox.com/mapbox-gl-js/v{{mapbox_gl_js_version}}/mapbox-gl.js.map > public/static/javascript/mapbox-gl.js.map
	curl -L https://api.tiles.mapbox.com/mapbox-gl-js/v{{mapbox_gl_js_version}}/mapbox-gl.css > public/static/css/mapbox-gl.css

# Uninstall Mapbox GL JS.
uninstall-mapbox-gl-js:
	rm public/static/javascript/mapbox-gl.js
	rm public/static/javascript/mapbox-gl.js.map
	rm public/static/css/mapbox-gl.css

# Local Variables:
# mode: makefile
# End:
