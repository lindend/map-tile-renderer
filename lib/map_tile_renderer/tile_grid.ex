defmodule MapTileRenderer.TileGrid do
    defstruct width: 0, height: 0, lat: 0, lon: 0, resolution: 0, tiles: %{}
    
    use GenServer

    def start_link(width, height, lat, lon, resolution, default_tile) do
        tile_grid = %MapTileRenderer.TileGrid{width: width, height: height, lat: lat, lon: lon,
                        resolution: resolution, tiles: make_tile_grid(width, height, default_tile)}
        GenServer.start_link(__MODULE__, tile_grid, [])
    end

    def stop(grid) do
        GenServer.stop(grid)
    end

    defp make_tile_grid(width, height, default_tile) do
        Map.new for row <- 0..height - 1, col <- 0..width - 1, do: {{row, col}, [default_tile]}
    end

    def render_polygon(grid, polygon) do
        GenServer.cast(grid, {:render, polygon})
    end

    def get_tiles(grid) do
        GenServer.call(grid, {:get_tiles})
    end

    def init(tile_grid) do
        {:ok, tile_grid}
    end

    def handle_cast({:render, polygon}, grid) do
        grid = %{grid | tiles: update_tiles(grid, polygon)}
        {:noreply, grid}
    end

    def handle_call({:get_tiles}, _from, grid) do
        {:reply, grid.tiles, grid}
    end

    defp update_tiles(grid, polygon) do
        Enum.reduce(0..grid.height - 1, grid.tiles, fn row, tiles ->
            lat = move_lat({grid.lat, grid.lon}, grid.resolution, row)

            polygon_intersections(lat, polygon)
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
        end)
    end

    defp to_grid_space(intersections, %{lat: lat, lon: lon, resolution: resolution, width: width}) do
        Enum.map(intersections, fn {type, intersection} ->
            lon_width = move_lon({lat, lon}, resolution, width) - lon
            {type, round((intersection - lon) / lon_width * width)}
        end)
    end

    defp polygon_intersections(lat, polygon) do
        Enum.flat_map(polygon.areas, fn {tile, vertices} ->
            MapTileRenderer.Intersection.polygon_scanline_intersections(lat, vertices)
            |> Enum.map(&({tile, &1}))
        end)
    end

    defp move_lat(start_pos, resolution, height) do
        {:ok, [new_lat, _]} = Geocalc.destination_point(start_pos, [90, 0], height * resolution)
        new_lat
    end

    defp move_lon({start_lat, start_lon} = start_pos, resolution, width) do
        {:ok, [_, new_lon]} = Geocalc.destination_point(start_pos, [start_lat, start_lon + 1.0], width * resolution)
        new_lon
    end
end