mapbox_gl_js_version = "0.50.0"
server_address = "localhost:8889"
geocode_api_address = "localhost:8990"
route_api_address = "localhost:8989"
geocode_data_planet = "https://github.com/OSMNames/OSMNames/releases/download/v2.0.4/planet-latest_geonames.tsv.gz"
tile_api_address = "127.0.0.1:8991"

# Open Atlasr in your favorite browser.
open: install
	open http://{{server_address}}

# Install Atlasr!
install: install-server install-api install-client

# Test Atlasr.
test: test-server test-client

# Uninstall Atlasr.
uninstall: uninstall-server uninstall-api uninstall-client

# Install the HTTP server.
install-server:
	cd source/server && \
		SERVER_ADDRESS={{server_address}} \
		ROUTE_API_ADDRESS={{route_api_address}} \
		GEOCODE_API_ADDRESS={{geocode_api_address}} \
		TILE_API_ADDRESS={{tile_api_address}} \
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
install-api: install-api-geocode install-api-route install-api-tile

# Uninstall all the APIs.
uninstall-api: uninstall-api-geocode uninstall-api-route

# Install the geocode API.
install-api-geocode: install-api-geocode-data install-api-geocode-indexer install-api-geocode-searcher

# Install/download data for the geocode API.
install-api-geocode-data: install-api-geocode-indexer
	cd source/api/geocode && \
		curl -L {{geocode_data_planet}} > planet.tsv.gz && \
		gzip -d planet.tsv.gz && \
		mkdir -p index && \
		./indexer/target/release/atlasr-api-geocode-indexer --source-file planet.tsv --index-directory index

# Install the indexer for the geocode API.
install-api-geocode-indexer:
	cd source/api/geocode/indexer && cargo build --release

# Install the searcher for the geocode API.
install-api-geocode-searcher:
	cd source/api/geocode/searcher && \
		GEOCODE_API_ADDRESS={{geocode_api_address}} \
		cargo build --release

uninstall-api-geocode:
	# noop

run-api-geocode-searcher:
	cd source/api/geocode/searcher && cargo run --release

# Install the route API (GraphHopper).
install-api-route:
	git submodule update --init source/api/route

# Uninstall the route API (GraphHopper).
uninstall-api-route:
	# noop

# Run the route API (GraphHopper) for a particular PBF zone.
run-api-route map_file='europe_switzerland': install-api-route
	cd source/api/route && ./graphhopper.sh web {{map_file}}.pbf

# Install the tile API.
install-api-tile:
	cd source/api/tile && \
		SERVER_ADDRESS={{server_address}} \
		TILE_API_ADDRESS={{tile_api_address}} \
		cargo build --release

# Run the tile API.
run-api-tile:
	cd source/api/tile && cargo run --release

# Uninstall the tile API.
uninstall-api-tile:
	# noop

#run-api-tile map_file='europe_switzerland': install-api-tile
#	cd source/api/tile && \
#		curl -L 'https://openmaptiles.com/download/WyJjOWUzNGM1NS04MDQxLTQ4MTMtYmUzMy0yNmFjMGUyN2I5MWIiLCItMSIsODcxM10.DsGknA.wk4qsZRjBSL8gQrp22h2CRpCyi4/osm-2017-07-03-v3.6.1-{{map_file}}.mbtiles?usage=open-source' > database/{{map_file}}.mbtiles

# Install client.
install-client: install-client-index install-client-application install-client-dependencies

# Test client.
test-client: test-client-application

# Uninstall client.
uninstall-client: uninstall-client-index uninstall-client-application

# Create a public `index.html` file.
install-client-index:
	cp source/client/src/index.html public/static/index.html
	sed -i '' "s@{MAP-PLACEHOLDER.svg}@`cat public/static/image/map-placeholder.svg | sed -E 's/^ +//g; s/"/'"'"'/g; s/</%3c/g; s/>/%3e/g; s/\#/%23/g' | tr -d "\n"`@" public/static/index.html

# Remove the public `index.html` file.
uninstall-client-index:
	rm -f public/static/index.html

# Compile the Elm application to JS.
install-client-application:
	cd source/client && elm make src/Main.elm --optimize --output ../../public/static/javascript/application.elm.js
	cd public/static/javascript && \
		uglifyjs application.elm.js \
			--compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | \
		uglifyjs \
			--mangle \
			--output=application.min.elm.js && \
		gzip --best --stdout application.min.elm.js > application.min.elm.js.gz && \
		brotli --best --stdout application.min.elm.js > application.min.elm.js.br

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
	cd public/static/javascript/ && \
		curl -L https://api.tiles.mapbox.com/mapbox-gl-js/v{{mapbox_gl_js_version}}/mapbox-gl.js > mapbox-gl.js && \
		curl -L https://api.tiles.mapbox.com/mapbox-gl-js/v{{mapbox_gl_js_version}}/mapbox-gl.js.map > mapbox-gl.js.map && \
		curl -L https://api.tiles.mapbox.com/mapbox-gl-js/v{{mapbox_gl_js_version}}/mapbox-gl.css > mapbox-gl.css && \
		uglifyjs \
			--compress \
			--mangle \
			--output=mapbox-gl.min.js mapbox-gl.js && \
		gzip --best --stdout mapbox-gl.min.js > mapbox-gl.min.js.gz && \
		brotli --best --stdout mapbox-gl.min.js > mapbox-gl.min.js.br

# Uninstall Mapbox GL JS.
uninstall-mapbox-gl-js:
	rm public/static/javascript/mapbox-gl.js
	rm public/static/javascript/mapbox-gl.js.map
	rm public/static/css/mapbox-gl.css

# Local Variables:
# mode: makefile
# End:
