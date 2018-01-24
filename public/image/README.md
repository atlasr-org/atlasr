# `map-placeholder.svg`

1. Raster a part of the map,
2. Install [`primitive`](https://github.com/fogleman/primitive),
3. `primitive -m 1 -n 60 -i map-rasterized.png -o map-triangles.svg`,
4. Optimise it with [SVGOMG](https://jakearchibald.github.io/svgomg/),
5. Put the paths (only) into the following template:
   ```xml
   <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="540" version="1">
     <filter id="blur">
       <feGaussianBlur stdDeviation="12" />
     </filter>
     <g filter="url(#blur)">
       …
     </g>
   </svg>
   ```
