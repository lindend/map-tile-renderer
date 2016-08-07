defmodule MapRasterizer do
    require Logger

    def rasterize(map_data, grid_width, grid_height, resolution) do
        polygons = Stream.map(map_data, &process_map_data &1)
        |> Stream.filter(fn p -> p != nil end)
        |> Enum.to_list

        rasterize_grids(polygons, grid_width, grid_height, resolution)
    end

    defp process_map_data(%MapTileRenderer.MapData.Area{type: type, vertices: vertices, bbox: bbox}) do
        %MapTileRenderer.Polygon{areas: [{type, vertices, bbox}], bbox: bbox}
    end

    defp process_map_data(%MapTileRenderer.MapData.MultiArea{areas: areas}) do
        poly_bbox = Enum.reduce(areas, hd(areas).bbox, fn %{bbox: {area_min, area_max}}, poly_box ->
            MapTileRenderer.Intersection.box_add_point(poly_box, area_min)
            |> MapTileRenderer.Intersection.box_add_point(area_max)
        end)

        %MapTileRenderer.Polygon{bbox: poly_bbox, areas: Enum.map(areas, fn area -> {area.type, area.vertices, area.bbox} end)}        
    end

    defp process_map_data(_) do
        nil
    end

    defp rasterize_grids(polygons, width, height, resolution) do
        start_lat = 57.6621
        start_lon = 11.8934

        (for col <- 0..4, row <- 0..4, do: {col, row})
        |> Stream.chunk(8, 8, [])
        |> Stream.map(fn chunk ->
            Enum.map(chunk, fn {col, row} ->
                Task.async(fn ->
                    Logger.info("Rasterizing tile #{col}, #{row}")
                    lat = MapTileRenderer.Coordinates.move_lat({start_lat, start_lon}, -resolution, height * row)
                    lon = MapTileRenderer.Coordinates.move_lon({start_lat, start_lon}, resolution, width * col)
                    {:ok, grid} = MapTileRenderer.TileGrid.start_link(width, height, lat, lon, resolution, :land)

                    grid_bbox = MapTileRenderer.TileGrid.get_bbox(grid)
                    
                    Enum.filter(polygons, fn %{bbox: bbox} -> MapTileRenderer.Intersection.box_vs_box?(grid_bbox, bbox) end)
                    |> Enum.each(fn polygon ->
                        MapTileRenderer.TileGrid.render_polygon(grid, polygon)
                    end)

                    tiles = MapTileRenderer.TileGrid.get_tiles(grid)
                    MapTileRenderer.TileGrid.stop(grid)
                    tiles
                end)
            end)
            |> Enum.map(&Task.await(&1, :infinity))
        end)
        |> Stream.concat
    end
end