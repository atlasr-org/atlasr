const atlasr = Elm.Atlasr.Main.fullscreen();

atlasr.ports.mapboxgl_create_map.subscribe(
    function (id) {
        var map = new mapboxgl.Map({
            container: id,
            style: 'https://openmaptiles.github.io/osm-bright-gl-style/style-cdn.json',
            center: [8.5456, 47.3739],
            zoom: 11
        });
    }
);
