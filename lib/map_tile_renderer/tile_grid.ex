defmodule MapTileRenderer.TileGrid do
    defstruct width: 0, height: 0, lat: 0, lon: 0, resolution: 0, tiles: %{}, bbox: {{0.0, 0.0}, {0.0, 0.0}}, row_bboxes: []
    
    use GenServer

    def start_link(width, height, lat, lon, resolution, default_tile) do
        bbox = calc_bbox(lon, lat, width, height, resolution)
        row_bboxes = make_row_bboxes(lon, lat, width, height, resolution)
        tile_grid = %MapTileRenderer.TileGrid{width: width, height: height, lat: lat, lon: lon, bbox: bbox,
                        resolution: resolution, tiles: make_tile_grid(width, height, default_tile),
                        row_bboxes: row_bboxes}
        GenServer.start_link(__MODULE__, tile_grid, [])
    end

    def stop(grid) do
        GenServer.stop(grid)
    end

    defp calc_bbox(lon, lat, width, height, resolution) do
        moved_lon = MapTileRenderer.Coordinates.move_lon({lat, lon}, resolution, width)
        moved_lat = MapTileRenderer.Coordinates.move_lat({lat, lon}, resolution, height)
        min_bounds = {min(lon, moved_lon), min(lat, moved_lat)}
        max_bounds = {max(lon, moved_lon), max(lat, moved_lat)}
        {min_bounds, max_bounds}
    end

    defp make_row_bboxes(lon, lat, width, height, resolution) do
        {{min_lon, _}, {max_lon, _}} = calc_bbox(lon, lat, width, height, resolution)
        Enum.map(0..height - 1, fn row ->
            row_lat = MapTileRenderer.Coordinates.move_lat({lat, lon}, resolution, row)
            {{min_lon, row_lat}, {max_lon, row_lat}}
        end)
    end

    defp make_tile_grid(width, height, default_tile) do
        Map.new for row <- 0..height - 1, col <- 0..width - 1, do: {{row, col}, [default_tile]}
    end

    def render_polygon(grid, polygon) do
        GenServer.call(grid, {:render, polygon})
    end

    def get_tiles(grid) do
        GenServer.call(grid, {:get_tiles})
    end

    def get_bbox(grid) do
        GenServer.call(grid, {:get_bbox})
    end

    def init(tile_grid) do
        {:ok, tile_grid}
    end

    def handle_call({:render, polygon}, _from, grid) do
        grid = %{grid | tiles: update_tiles(grid, polygon)}
        {:reply, :ok, grid}
    end

    def handle_call({:get_tiles}, _from, grid) do
        {:reply, grid.tiles, grid}
    end

    def handle_call({:get_bbox}, _from, grid) do
        {:reply, grid.bbox, grid}
    end

    defp update_tiles(grid, polygon) do
        Enum.with_index(grid.row_bboxes)
        |> Enum.reduce(grid.tiles, fn {row_bbox, row}, tiles ->
            lat = MapTileRenderer.Coordinates.move_lat({grid.lat, grid.lon}, grid.resolution, row)

            apply_intersections(row, lat, polygon, grid, tiles, row_bbox)
        end)
    end

    defp apply_intersections(row, lat, polygon, grid, tiles, bbox) do
        polygon_intersections(lat, polygon, bbox)
            |> to_grid_space(grid)
            |> Enum.sort_by(fn {_, intersection} -> intersection end)
            |> Enum.chunk(2)
            |> Enum.filter(fn [{_, start}, {_, stop}] -> stop > 0 && start < grid.width end)
            |> Enum.reduce(tiles, fn [{start_tile, start}, {_, stop}], tiles ->
                Enum.reduce(start..stop, tiles, fn col, tiles ->
                    case Map.has_key?(tiles, {row, col}) do
                        true ->
                            {_, tiles} = Map.get_and_update!(tiles, {row, col}, &({&1, [start_tile | &1]}))
                            tiles
                        _ -> tiles
                    end
                end)
            end)
    end

    defp to_grid_space(intersections, %{lat: lat, lon: lon, resolution: resolution, width: width}) do
        Enum.map(intersections, fn {type, intersection} ->
            lon_width = MapTileRenderer.Coordinates.move_lon({lat, lon}, resolution, width) - lon
            {type, round((intersection - lon) / lon_width * width)}
        end)
    end

    defp polygon_intersections(lat, polygon, bbox) do
        Enum.filter(polygon.areas, fn {_, _, area_bbox} ->
            MapTileRenderer.Intersection.box_vs_box?(bbox, area_bbox)
        end)
        |> Enum.flat_map(fn {tile, vertices, _bbox} ->
            MapTileRenderer.Intersection.polygon_scanline_intersections(lat, vertices)
            |> Enum.map(&({tile, &1}))
        end)
    end
end