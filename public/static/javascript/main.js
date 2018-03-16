(
    () => {
        const atlasr  = Elm.Atlasr.Main.fullscreen();
        let   map     = null;
        let   markers = [];

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
        atlasr.ports.mapboxgl_add_marker.subscribe(
            ([longitude, latitude]) => {
                const marker =
                    new mapboxgl.Marker()
                        .setLngLat([longitude, latitude])
                        .addTo(map);

                markers.push(marker);
            }
        );
        atlasr.ports.mapboxgl_remove_markers.subscribe(
            () => {
                for (let marker of markers) {
                    marker.remove();
                }

                markers = [];
            }
        );
        atlasr.ports.mapboxgl_connect_markers.subscribe(
            () => {
                setTimeout(
                    () => {
                        let coordinates = [];

                        for (let marker of markers) {
                            coordinates.push(marker.getLngLat().toArray());
                        }

                        console.log(coordinates);

                        map.addLayer({
                            'id': 'route',
                            'type': 'line',
                            'source': {
                                'type': 'geojson',
                                'data': {
                                    'type': 'Feature',
                                    'properties': {},
                                    'geometry': {
                                        'type': 'LineString',
                                        'coordinates': coordinates
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
                    },
                    2000
                );
            }
        );
    }
)();
