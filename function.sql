CREATE OR REPLACE FUNCTION mvt(z integer, x integer, y integer)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    mvt_output text;
BEGIN
    WITH 
    -- Define the bounds of the tile using the provided Z, X, Y coordinates
    bounds AS (
        SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
    -- Transform the geometries from EPSG:4326 to EPSG:3857 and clip them to the tile bounds
    mvtgeom AS (
        SELECT 
            -- include the name and id only at zoom 13 to make low-zoom tiles smaller
            CASE 
            WHEN z > 13 THEN id
            ELSE NULL
            END AS id,
            CASE 
            WHEN z > 13 THEN names::json->>'primary'
            ELSE NULL
            END AS primary_name,
            categories::json->>'main' as main_category,
            ST_AsMVTGeom(
                ST_Transform(wkb_geometry, 3857), -- Transform the geometry to Web Mercator
                bounds.geom,
                4096, -- The extent of the tile in pixels (commonly 256 or 4096)
                0,    -- Buffer around the tile in pixels
                true  -- Clip geometries to the tile extent
            ) AS geom
        FROM 
            places, bounds
        WHERE 
            ST_Intersects(ST_Transform(wkb_geometry, 3857), bounds.geom)
    )
    -- Generate the MVT from the clipped geometries
    SELECT INTO mvt_output encode(ST_AsMVT(mvtgeom, 'places', 4096, 'geom'),'base64')
    FROM mvtgeom;

    RETURN mvt_output;
END;
$$;