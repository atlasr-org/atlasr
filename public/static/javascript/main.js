(
    () => {
        const atlasr                     = Elm.Atlasr.Main.fullscreen();
        const LAYER_ROUTE_MARKERS_PREFIX = 'markers-';
        let   map                        = null;
        let   layer_route_markers        = '';
        let   markers                    = [];

        atlasr.ports.mapboxgl_create_map.subscribe(
            ([id, options]) => {
                mapboxgl.accessToken = 'undefined';

                map = new mapboxgl.Map({
                    container         : id,
                    style             : options.style,
                    center            : options.center,
                    zoom              : options.zoom,
                    hash              : options.hash,
                    pitchWithRotate   : options.pitchWithRotate,
                    attributionControl: options.attributionControl,
                    dragRotate        : options.dragRotate,
                    dragPan           : options.dragPan,
                    keyboard          : options.keyboard,
                    doubleClickZoom   : options.doubleClickZoom,
                    touchZoomRotate   : options.touchZoomRotate,
                    trackResize       : options.trackResize,
                    renderWorldCopies : options.renderWorldCopies
                });
                map.addControl(
                    new mapboxgl.GeolocateControl(
                        {
                            positionOptions: {
                                enableHighAccuracy: true
                            },
                            trackUserLocation: true
                        }
                    ),
                    'bottom-right'
                );
                map.addControl(
                    new mapboxgl.NavigationControl(),
                    'bottom-right'
                );
            }
        );
        atlasr.ports.mapboxgl_fly_to.subscribe(
            (cameraOptions) => {
                map.flyTo(cameraOptions);
            }
        );
        atlasr.ports.mapboxgl_add_markers.subscribe(
            (positions) => {
                for (let [longitude, latitude] of positions) {
                    markers.push(
                        new mapboxgl.Marker()
                            .setLngLat([longitude, latitude])
                            .addTo(map)
                    );
                }
            }
        );
        atlasr.ports.mapboxgl_remove_markers.subscribe(
            () => {
                for (let marker of markers) {
                    marker.remove();
                }

                markers = [];

                if (undefined !== map.getLayer(layer_route_markers)) {
                    map.removeLayer(layer_route_markers);
                }
            }
        );
        atlasr.ports.mapboxgl_connect_markers.subscribe(
            (positions) => {
                if (1 < positions.length) {
                    layer_route_markers = LAYER_ROUTE_MARKERS_PREFIX + guid();

                    map.addLayer({
                        'id': layer_route_markers,
                        'type': 'line',
                        'source': {
                            'type': 'geojson',
                            'data': {
                                'type': 'Feature',
                                'properties': {},
                                'geometry': {
                                    'type': 'LineString',
                                    'coordinates': positions
                                }
                            }
                        },
                        'layout': {
                            'line-join': 'round',
                            'line-cap': 'round'
                        },
                        'paint': {
                            'line-color': '#00b3fd',
                            'line-width': 8
                        }
                    });
                }
            }
        );

        function guid() {
            const s4 = () => {
                return Math.floor((1 + Math.random()) * 0x10000)
                    .toString(16)
                    .substring(1);
            };

            return s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4();
        }
    }
)();
