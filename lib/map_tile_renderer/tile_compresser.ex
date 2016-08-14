defmodule MapTileRenderer.TileCompresser do
    def compress(chunk, width, height, resolution) do
        layers = split_layers(chunk)
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

    defp run_length_encode(layer) do
        Enum.chunk_by(layer, &(&1)) |> Enum.flat_map(fn tiles -> [length(tiles), hd tiles] end)
    end

    defp to_protobuf_layer(layer) do
        %MapTileRenderer.FileFormat.TileLayer{tiles: run_length_encode(layer)}
    end
end