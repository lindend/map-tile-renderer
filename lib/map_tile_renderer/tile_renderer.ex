defmodule MapTileRenderer.TileRenderer do
    require Logger
    
    def render(chunk) do
        Enum.sort_by(chunk, fn {coords, _} -> coords end)
            |> Enum.map(fn {_, cell_data} -> cell_data end)
            |> Enum.map(fn tile -> Enum.group_by(tile, &MapTileRenderer.MapData.AreaType.layer/1) end)
            |> Enum.map(fn groups -> Enum.map(groups, fn {_group, values} ->
                    Enum.sort_by(values, &MapTileRenderer.MapData.AreaType.priority/1)
                    |> hd
                    |> MapTileRenderer.MapData.AreaType.tile_index
                end)
            end)
    end
end