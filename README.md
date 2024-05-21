# supabase-vector-tile

Use MapLibre's `addProtocol` to visualize large PostGIS tables, by calling a custom function using the Supabase JS client.

## Steps

Use the Overture CLI to download places for a bounding box.

```
pip install overturemaps
overturemaps download --bbox=103.570233,1.125077,104.115855,1.490957 -f geojson --type=place -o places.geojson
```

Use `ogr2ogr`:

You can install `GDAL` via homebrew `brew install gdal` or follow the [download instructions](https://gdal.org/download.html).

```
PG_USE_COPY=true ogr2ogr -f pgdump places.sql places.geojson
```

Enable PostGIS in your Supabase project:

```sql
create extension postgis with schema extensions;
```

Import this as the `places` table in a Supabase database:

```
psql -h aws-0-us-west-1.pooler.supabase.com -p 5432 -d postgres -U postgres.project-ref < places.sql
```

Create a new Postgres Function called `mvt` by running the SQL in [function.sql](function.sql).

Modify that pl/pgsql function to include only the data you need to visualize, and consider NULLing some columns at low zooms to make tiles smaller.

Edit `index.html` with your Supabase URL and anonymous key.

You will also need an index on your `places` table:

```
CREATE INDEX webmercator ON public.places USING gist (st_transform(wkb_geometry, 3857))
```
