defmodule MapTileRenderer.Coordinates do
    def move_lat(start_pos, resolution, height) do
        {:ok, [new_lat, _]} = Geocalc.destination_point(start_pos, [90, 0], height * resolution)
        new_lat
    end

    def move_lon({start_lat, start_lon} = start_pos, resolution, width) do
        {:ok, [_, new_lon]} = Geocalc.destination_point(start_pos, [start_lat, start_lon + 1.0], width * resolution)
        new_lon
    end
end