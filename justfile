mapbox_gl_js_version = "0.44.1"
route_api_url = "http://localhost:8989"
geocode_data_planet = "https://github.com/OSMNames/OSMNames/releases/download/v2.0.4/planet-latest-100k_geonames.tsv.gz"

# Open Atlasr in your favorite browser.
open: install
	open http://127.0.0.1:8889

# Install Atlasr!
install: install-server install-api install-client

# Test Atlasr.
test: test-server test-client

# Uninstall Atlasr.
uninstall: uninstall-server uninstall-api uninstall-client

# Install the HTTP server.
install-server:
	cd source/server && \
	    ROUTE_API_URL={{route_api_url}} \
	    cargo build --release

# Test the HTTP server.
test-server:
	cd source/server && cargo test

# Uninstall the HTTP server.
uninstall-server:
	rm -rf source/server/Cargo.lock source/server/target

# Run the HTTP server (will not exit).
run-server: install-server
	cd source/server && cargo run --release

# Install all the APIs.
install-api: install-api-route install-api-geocode

# Uninstall all the APIs.
uninstall-api: uninstall-api-route uninstall-api-geocode

# Install the route API (GraphHopper).
install-api-route:
	git submodule update --init source/api/route

# Uninstall the route API (GraphHopper).
uninstall-api-route:
	# noop

# Run the route API (GraphHopper) for a particular PBF zone.
run-api-route map_file='europe_switzerland': install-api-route
	cd source/api/route && ./graphhopper.sh web {{map_file}}.pbf

# Install the geocode API.
install-api-geocode: install-api-geocode-data install-api-geocode-indexer install-api-geocode-searcher

# Install/download data for the geocode API.
install-api-geocode-data:
	cd source/api/geocode && \
		curl -L {{geocode_data_planet}} > planet.tsv.gz && \
		gzip -d planet.tsv.gz

# Install the indexer for the geocode API.
install-api-geocode-indexer:
	cd source/api/geocode/indexer && cargo build --release

# Install the searcher for the geocode API.
install-api-geocode-searcher:
	cd source/api/geocode/indexer && cargo build --release

uninstall-api-geocode:
	# noop

# Install client.
install-client: install-client-index install-client-application install-client-dependencies

# Test client.
test-client: test-client-application

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
	cd source/client && elm-make src/Main.elm --output ../../public/static/javascript/application.elm.js

# Test the Elm application.
test-client-application:
	cd source/client && elm-test tests/unit/

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
