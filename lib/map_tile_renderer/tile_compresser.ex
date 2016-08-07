defmodule MapTileRenderer.TileCompresser do
    def compress(chunk, width, height, resolution) do
        layers = split_layers(chunk)
        |> Enum.map(&delta_encode/1)
        |> Enum.map(&to_protobuf_layer/1)

        %MapTileRenderer.FileFormat.TileChunk{width: width, height: height, resolution: resolution, tile_layers: layers}
        |> MapTileRenderer.FileFormat.TileChunk.encode
        |> :zlib.compress
    end

    defp split_layers(chunk) do
        layer = Enum.map(chunk, fn tile ->
            case tile do
                [] -> 0
                _ -> hd tile
            end
        end)

        chunk = Enum.map(chunk, fn tile ->
            case tile do
                [] -> []
                _ -> tl tile
            end
        end)

        if Enum.all?(chunk, fn c -> c == [] end) do
            [layer]
        else
            [layer | split_layers(chunk)]
        end
    end

    defp delta_encode(layer) do
        {encoded, _} = Enum.map_reduce(layer, 0, fn t, acc ->
            {t - acc, t}
        end)
        encoded
    end

    defp to_protobuf_layer(layer) do
        first = hd layer
        cond do
            Enum.all?(layer, fn t -> t == first end) -> %MapTileRenderer.FileFormat.TileLayer{single_tile: first}
            true -> %MapTileRenderer.FileFormat.TileLayer{tiles: layer}
        end
    end
end