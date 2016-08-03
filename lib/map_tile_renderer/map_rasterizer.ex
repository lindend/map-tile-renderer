defmodule MapRasterizer do
    def render([start_lat, start_lon] = start_pos, map_data, resolution, width, height) do
        Enum.stream(map_data, &process_map_data &1)
    end

    defp process_map_data(%MapTileRenderer.MapData.Area{type: type, vertices: vertices} = area) do
        %MapTileRenderer.Polygon{areas: [{type, vertices}]}
    end

    defp process_map_data(%MapTileRenderer.MapData.MultiArea{areas: areas} = multi_area) do
        %MapTileRenderer.Polygon{areas: Enum.map(areas, fn area -> {area.type, area.vertices} end)}        
    end
end