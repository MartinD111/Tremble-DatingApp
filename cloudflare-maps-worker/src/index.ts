const STYLE_JSON = {
  version: 8,
  name: "Tremble Premium Dark",
  metadata: {
    "tremble:version": "1.0.0",
    "tremble:description":
      "Premium Apple Maps dark aesthetic with Tremble brand identity",
  },
  sources: {
    protomaps: {
      type: "vector",
      url: "pmtiles://https://maps.trembledating.com/planet.pmtiles",
    },
  },
  sprite: "https://protomaps.github.io/basemaps-assets/sprites/v4/dark",
  glyphs:
    "https://protomaps.github.io/basemaps-assets/fonts/{fontstack}/{range}.pbf",
  layers: [
    {
      id: "background",
      type: "background",
      paint: {
        "background-color": "#1A1A18",
      },
    },
    {
      id: "earth",
      type: "fill",
      source: "protomaps",
      "source-layer": "earth",
      paint: {
        "fill-color": "#1A1A18",
      },
    },
    {
      id: "landuse_residential",
      type: "fill",
      source: "protomaps",
      "source-layer": "landuse",
      filter: ["in", "kind", "residential", "suburb"],
      paint: {
        "fill-color": "#1C1C1A",
      },
    },
    {
      id: "landuse_commercial",
      type: "fill",
      source: "protomaps",
      "source-layer": "landuse",
      filter: [
        "in",
        "kind",
        "commercial",
        "retail",
        "industrial",
        "university",
        "school",
        "hospital",
      ],
      paint: {
        "fill-color": "#1E1E1C",
      },
    },
    {
      id: "landuse_parks",
      type: "fill",
      source: "protomaps",
      "source-layer": "landuse",
      filter: [
        "in",
        "kind",
        "park",
        "forest",
        "wood",
        "meadow",
        "nature_reserve",
        "garden",
        "golf_course",
        "grass",
        "cemetery",
        "recreation_ground",
      ],
      paint: {
        "fill-color": "#17221A",
      },
    },
    {
      id: "natural_wood",
      type: "fill",
      source: "protomaps",
      "source-layer": "natural",
      filter: ["in", "kind", "wood", "forest", "scrub", "heath", "grassland"],
      paint: {
        "fill-color": "#17221A",
      },
    },
    {
      id: "natural_sand",
      type: "fill",
      source: "protomaps",
      "source-layer": "natural",
      filter: ["==", "kind", "sand"],
      paint: {
        "fill-color": "#26221B",
      },
    },
    {
      id: "water",
      type: "fill",
      source: "protomaps",
      "source-layer": "water",
      paint: {
        "fill-color": "#131924",
      },
    },
    {
      id: "water_lines",
      type: "line",
      source: "protomaps",
      "source-layer": "water",
      filter: ["==", "$type", "LineString"],
      paint: {
        "line-color": "#131924",
        "line-width": ["interpolate", ["linear"], ["zoom"], 10, 0.5, 16, 3],
      },
    },
    {
      id: "buildings-flat",
      type: "fill",
      source: "protomaps",
      "source-layer": "buildings",
      maxzoom: 14.5,
      paint: {
        "fill-color": "#222220",
        "fill-opacity": 0.75,
      },
    },
    {
      id: "buildings-3d",
      type: "fill-extrusion",
      source: "protomaps",
      "source-layer": "buildings",
      minzoom: 14.5,
      paint: {
        "fill-extrusion-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          14.5,
          "#222220",
          17,
          "#282826",
        ],
        "fill-extrusion-height": [
          "coalesce",
          ["get", "height"],
          ["*", ["coalesce", ["get", "levels"], 1], 3.5],
          10,
        ],
        "fill-extrusion-base": [
          "coalesce",
          ["get", "min_height"],
          ["*", ["coalesce", ["get", "min_levels"], 0], 3.5],
          0,
        ],
        "fill-extrusion-opacity": 0.85,
      },
    },
    {
      id: "boundaries",
      type: "line",
      source: "protomaps",
      "source-layer": "boundaries",
      paint: {
        "line-color": "#3C3C39",
        "line-width": ["interpolate", ["linear"], ["zoom"], 3, 0.5, 10, 2],
      },
    },
    {
      id: "roads_casing",
      type: "line",
      source: "protomaps",
      "source-layer": "roads",
      filter: ["in", "kind", "motorway", "trunk", "primary", "secondary"],
      paint: {
        "line-color": "#141412",
        "line-width": ["interpolate", ["linear"], ["zoom"], 12, 1.5, 18, 12],
        "line-opacity": ["interpolate", ["linear"], ["zoom"], 12, 0.0, 14, 1.0],
      },
    },
    {
      id: "roads_minor",
      type: "line",
      source: "protomaps",
      "source-layer": "roads",
      filter: [
        "in",
        "kind",
        "tertiary",
        "residential",
        "unclassified",
        "service",
      ],
      paint: {
        "line-color": "#242422",
        "line-width": ["interpolate", ["linear"], ["zoom"], 12, 0.5, 18, 4.0],
      },
    },
    {
      id: "roads_major",
      type: "line",
      source: "protomaps",
      "source-layer": "roads",
      filter: ["in", "kind", "primary", "secondary"],
      paint: {
        "line-color": "#2E2E2C",
        "line-width": ["interpolate", ["linear"], ["zoom"], 10, 0.8, 18, 8.0],
      },
    },
    {
      id: "roads_highway",
      type: "line",
      source: "protomaps",
      "source-layer": "roads",
      filter: ["in", "kind", "motorway", "trunk"],
      paint: {
        "line-color": "#383835",
        "line-width": ["interpolate", ["linear"], ["zoom"], 6, 0.8, 18, 10.0],
      },
    },
    {
      id: "roads_paths",
      type: "line",
      source: "protomaps",
      "source-layer": "roads",
      filter: ["in", "kind", "path", "footway", "cycleway", "pedestrian"],
      paint: {
        "line-color": "#1D1D1B",
        "line-width": ["interpolate", ["linear"], ["zoom"], 14, 0.5, 18, 1.5],
        "line-dasharray": [2, 2],
      },
    },
    {
      id: "transit_lines",
      type: "line",
      source: "protomaps",
      "source-layer": "transit",
      filter: ["==", "kind", "rail"],
      paint: {
        "line-color": "#2A222B",
        "line-width": ["interpolate", ["linear"], ["zoom"], 10, 0.5, 18, 2.0],
        "line-dasharray": [4, 4],
      },
    },
    {
      id: "place_country",
      type: "symbol",
      source: "protomaps",
      "source-layer": "places",
      filter: ["==", "kind", "country"],
      layout: {
        "text-field": ["coalesce", ["get", "name:en"], ["get", "name"]],
        "text-font": ["Noto Sans Bold"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 2, 9, 6, 16],
        "text-transform": "uppercase",
        "text-letter-spacing": 0.15,
      },
      paint: {
        "text-color": "#FAFAF7",
        "text-halo-color": "#1A1A18",
        "text-halo-width": 1.8,
      },
    },
    {
      id: "place_region",
      type: "symbol",
      source: "protomaps",
      "source-layer": "places",
      filter: ["==", "kind", "state"],
      layout: {
        "text-field": ["coalesce", ["get", "name:en"], ["get", "name"]],
        "text-font": ["Noto Sans Regular"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 4, 8, 8, 12],
        "text-transform": "uppercase",
        "text-letter-spacing": 0.1,
      },
      paint: {
        "text-color": "#E5E5E2",
        "text-halo-color": "#1A1A18",
        "text-halo-width": 1.5,
      },
    },
    {
      id: "place_city",
      type: "symbol",
      source: "protomaps",
      "source-layer": "places",
      filter: ["in", "kind", "city", "town"],
      layout: {
        "text-field": ["coalesce", ["get", "name:en"], ["get", "name"]],
        "text-font": ["Noto Sans Bold"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 8, 10, 16, 16],
      },
      paint: {
        "text-color": "#FAFAF7",
        "text-halo-color": "#1A1A18",
        "text-halo-width": 1.5,
      },
    },
    {
      id: "place_suburb",
      type: "symbol",
      source: "protomaps",
      "source-layer": "places",
      filter: ["in", "kind", "suburb", "neighbourhood", "village"],
      layout: {
        "text-field": ["coalesce", ["get", "name:en"], ["get", "name"]],
        "text-font": ["Noto Sans Regular"],
        "text-size": ["interpolate", ["linear"], ["zoom"], 12, 9, 16, 12],
      },
      paint: {
        "text-color": "#D8D8D5",
        "text-halo-color": "#1A1A18",
        "text-halo-width": 1.0,
      },
    },
    {
      id: "road_labels",
      type: "symbol",
      source: "protomaps",
      "source-layer": "roads",
      filter: [
        "in",
        "kind",
        "motorway",
        "trunk",
        "primary",
        "secondary",
        "tertiary",
      ],
      minzoom: 13,
      layout: {
        "text-field": ["get", "name"],
        "text-font": ["Noto Sans Regular"],
        "text-size": 9,
        "symbol-placement": "line",
        "text-rotation-alignment": "map",
      },
      paint: {
        "text-color": "#BFBFBC",
        "text-halo-color": "#1A1A18",
        "text-halo-width": 1.0,
      },
    },
    {
      id: "pois",
      type: "symbol",
      source: "protomaps",
      "source-layer": "pois",
      minzoom: 14.5,
      layout: {
        "text-field": ["get", "name"],
        "text-font": ["Noto Sans Regular"],
        "text-size": 9.5,
        "text-offset": [0, 0.6],
        "text-anchor": "top",
      },
      paint: {
        "text-color": "#E5E5E2",
        "text-halo-color": "#1A1A18",
        "text-halo-width": 1.0,
      },
    },
  ],
};
import {
  Compression,
  EtagMismatch,
  PMTiles,
  RangeResponse,
  ResolvedValueCache,
  Source,
  TileType,
  tileTypeExt,
} from "pmtiles";
import { pmtiles_path, tile_path } from "../../shared/index";

interface Env {
  // biome-ignore lint: config name
  ALLOWED_ORIGINS?: string;
  // biome-ignore lint: config name
  BUCKET: R2Bucket;
  // biome-ignore lint: config name
  CACHE_CONTROL?: string;
  // biome-ignore lint: config name
  PMTILES_PATH?: string;
  // biome-ignore lint: config name
  PUBLIC_HOSTNAME?: string;
}

class KeyNotFoundError extends Error {}

async function nativeDecompress(
  buf: ArrayBuffer,
  compression: Compression
): Promise<ArrayBuffer> {
  if (compression === Compression.None || compression === Compression.Unknown) {
    return buf;
  }
  if (compression === Compression.Gzip) {
    const stream = new Response(buf).body;
    const result = stream?.pipeThrough(new DecompressionStream("gzip"));
    return new Response(result).arrayBuffer();
  }
  throw new Error("Compression method not supported");
}

const CACHE = new ResolvedValueCache(25, undefined, nativeDecompress);

class R2Source implements Source {
  env: Env;
  archiveName: string;

  constructor(env: Env, archiveName: string) {
    this.env = env;
    this.archiveName = archiveName;
  }

  getKey() {
    return this.archiveName;
  }

  async getBytes(
    offset: number,
    length: number,
    signal?: AbortSignal,
    etag?: string
  ): Promise<RangeResponse> {
    const resp = await this.env.BUCKET.get(
      pmtiles_path(this.archiveName, this.env.PMTILES_PATH),
      {
        range: { offset: offset, length: length },
        onlyIf: { etagMatches: etag },
      }
    );
    if (!resp) {
      throw new KeyNotFoundError("Archive not found");
    }

    const o = resp as R2ObjectBody;

    if (!o.body) {
      throw new EtagMismatch();
    }

    const a = await o.arrayBuffer();
    return {
      data: a,
      etag: o.etag,
      cacheControl: o.httpMetadata?.cacheControl,
      expires: o.httpMetadata?.cacheExpiry?.toISOString(),
    };
  }
}

export default {
  async fetch(
    request: Request,
    env: Env,
    ctx: ExecutionContext
  ): Promise<Response> {
    let allowedOrigin = "";
    if (typeof env.ALLOWED_ORIGINS !== "undefined") {
      const origin = request.headers.get("Origin");
      for (const o of env.ALLOWED_ORIGINS.split(",")) {
        if (o === origin || o === "*") {
          allowedOrigin = o || "*";
          break;
        }
      }
    }

    // Handle CORS preflight (OPTIONS)
    if (request.method.toUpperCase() === "OPTIONS") {
      const headers = new Headers();
      if (allowedOrigin) {
        headers.set("Access-Control-Allow-Origin", allowedOrigin);
      }
      headers.set("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS");
      headers.set("Access-Control-Allow-Headers", "Range, Content-Type");
      headers.set("Access-Control-Max-Age", "86400");
      headers.set("Vary", "Origin");
      return new Response(undefined, { status: 204, headers });
    }

    if (
      request.method.toUpperCase() !== "GET" &&
      request.method.toUpperCase() !== "HEAD"
    ) {
      return new Response(undefined, { status: 405 });
    }

    const url = new URL(request.url);

    // Serve style JSON
    if (
      url.pathname === "/style.json" ||
      url.pathname === "/tremble_dark_style.json"
    ) {
      const headers = new Headers();
      headers.set("Content-Type", "application/json");
      if (allowedOrigin) {
        headers.set("Access-Control-Allow-Origin", allowedOrigin);
      }
      headers.set("Vary", "Origin");
      return new Response(JSON.stringify(STYLE_JSON), { headers, status: 200 });
    }

    // Support serving raw .pmtiles files directly from R2 (e.g. /planet.pmtiles)
    if (url.pathname.endsWith(".pmtiles")) {
      const name = url.pathname.slice(1); // e.g. "planet.pmtiles"
      const rangeHeader = request.headers.get("Range");

      const options: R2GetOptions = {};
      if (rangeHeader) {
        const rangeMatch = rangeHeader.match(/bytes=(\d+)-(\d+)?/);
        if (rangeMatch) {
          options.range = {
            offset: parseInt(rangeMatch[1]),
            length: rangeMatch[2]
              ? parseInt(rangeMatch[2]) - parseInt(rangeMatch[1]) + 1
              : undefined,
          };
        }
      }

      const resp = await env.BUCKET.get(
        pmtiles_path(name.substring(0, name.length - 8), env.PMTILES_PATH),
        options
      );

      if (!resp || !("body" in resp)) {
        return new Response("Not Found", { status: 404 });
      }

      const headers = new Headers();
      resp.writeHttpMetadata(headers);
      headers.set("etag", resp.etag);
      headers.set("Accept-Ranges", "bytes");
      if (allowedOrigin) {
        headers.set("Access-Control-Allow-Origin", allowedOrigin);
      }
      headers.set("Access-Control-Allow-Headers", "Range, Content-Type");
      headers.set("Vary", "Origin");

      const status = rangeHeader ? 206 : 200;
      return new Response(resp.body, {
        headers,
        status,
      });
    }

    const { ok, name, tile, ext } = tile_path(url.pathname);

    const cache = caches.default;

    if (!ok) {
      return new Response("Invalid URL", { status: 404 });
    }

    const cached = await cache.match(request.url);
    if (cached) {
      const respHeaders = new Headers(cached.headers);
      if (allowedOrigin)
        respHeaders.set("Access-Control-Allow-Origin", allowedOrigin);
      respHeaders.set("Vary", "Origin");

      return new Response(cached.body, {
        headers: respHeaders,
        status: cached.status,
      });
    }

    const cacheableResponse = (
      body: ArrayBuffer | string | undefined,
      cacheableHeaders: Headers,
      status: number
    ) => {
      cacheableHeaders.set(
        "Cache-Control",
        env.CACHE_CONTROL || "public, max-age=86400"
      );

      const cacheable = new Response(body, {
        headers: cacheableHeaders,
        status: status,
      });

      ctx.waitUntil(cache.put(request.url, cacheable));

      const respHeaders = new Headers(cacheableHeaders);
      if (allowedOrigin)
        respHeaders.set("Access-Control-Allow-Origin", allowedOrigin);
      respHeaders.set("Vary", "Origin");
      return new Response(body, { headers: respHeaders, status: status });
    };

    const cacheableHeaders = new Headers();
    const source = new R2Source(env, name);
    const p = new PMTiles(source, CACHE, nativeDecompress);
    try {
      const pHeader = await p.getHeader();

      if (!tile) {
        cacheableHeaders.set("Content-Type", "application/json");
        const t = await p.getTileJson(
          `https://${env.PUBLIC_HOSTNAME || url.hostname}/${name}`
        );
        return cacheableResponse(JSON.stringify(t), cacheableHeaders, 200);
      }

      if (tile[0] < pHeader.minZoom || tile[0] > pHeader.maxZoom) {
        return cacheableResponse(undefined, cacheableHeaders, 404);
      }

      const extToType: Record<string, TileType> = {
        mvt: TileType.Mvt,
        pbf: TileType.Mvt, // allow this for now. Eventually we will delete this in favor of .mvt
        png: TileType.Png,
        jpg: TileType.Jpeg,
        webp: TileType.Webp,
        avif: TileType.Avif,
      };

      const expectedType = extToType[ext];
      if (
        pHeader.tileType !== expectedType &&
        tileTypeExt(pHeader.tileType) !== ""
      ) {
        return cacheableResponse(
          `Bad request: requested .${ext} but archive has type ${tileTypeExt(
            pHeader.tileType
          )}`,
          cacheableHeaders,
          400
        );
      }

      const tiledata = await p.getZxy(tile[0], tile[1], tile[2]);

      switch (pHeader.tileType) {
        case TileType.Mvt:
          cacheableHeaders.set("Content-Type", "application/x-protobuf");
          break;
        case TileType.Png:
          cacheableHeaders.set("Content-Type", "image/png");
          break;
        case TileType.Jpeg:
          cacheableHeaders.set("Content-Type", "image/jpeg");
          break;
        case TileType.Webp:
          cacheableHeaders.set("Content-Type", "image/webp");
          break;
      }

      if (tiledata) {
        return cacheableResponse(tiledata.data, cacheableHeaders, 200);
      }
      return cacheableResponse(undefined, cacheableHeaders, 204);
    } catch (e) {
      if (e instanceof KeyNotFoundError) {
        return cacheableResponse("Archive not found", cacheableHeaders, 404);
      }
      throw e;
    }
  },
};
