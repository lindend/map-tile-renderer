defmodule MapRasterizer do
    def render([start_lat, start_lon] = start_pos, map_data, resolution, width, height) do
        tiles = Enum.map(0..height - 1, fn row ->
            lat = move_lat(start_pos, resolution, row)

            polygons = polygon_intersections(map_data, lat)

            row_tiles = Enum.map(0..width - 1, fn col ->
                move_lon([lat, start_lon], resolution, col)
            end)


        end)
    end

    defp move_lat(start_pos, resolution, height) do
        [new_lat, _] = Geocalc.destination_point(start_pos, [-90, 0], height * resolution)
        new_lat
    end

    defp move_lon({start_lat, start_lon} = start_pos, resolution, width) do
        [_, new_lon] = Geocalc.destination_point(start_pos, [start_lat, start_lon + 1.0], width * resolution)
        [new_lon]
    end

    def polygon_intersections(area, lat) do

    end
end