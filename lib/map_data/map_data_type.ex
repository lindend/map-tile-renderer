defmodule MapTileRenderer.MapData.Type do
    def type(tags)

    def type(%{"landuse" => "forest"}), do: :forest

    def(_) do
        :land
    end
end