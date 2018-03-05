(
    () => {
        const atlasr = Elm.Atlasr.Main.fullscreen();
        let   map    = null;

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
        atlasr.ports.mapboxgl_jump_to.subscribe(
            (cameraOptions) => {
                map.jumpTo(cameraOptions);
            }
        );
    }
)();
