const atlasr = Elm.Atlasr.Main.fullscreen();

atlasr.ports.mapboxgl_create_map.subscribe(
    function ([id, options]) {
        var map = new mapboxgl.Map({
            container: id,
            style    : options.style,
            center   : options.center,
            zoom     : options.zoom
        });
    }
);
