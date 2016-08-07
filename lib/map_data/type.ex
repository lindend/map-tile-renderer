defmodule MapTileRenderer.MapData.Type do
    require Logger
    def type(tags, types) do
        types = Enum.filter(types, fn {_type, {type_tags, _, _, _}} ->
            Enum.any?(type_tags, fn type_tag ->
                case type_tag do
                    values when is_list(values) -> Enum.all?(values, fn kv -> match_tags(tags, kv) end)
                    kv -> match_tags(tags, kv)
                end
            end)
        end)
        case types do
            [] -> :empty
            ts ->
                {type, _} = Enum.max_by(ts, fn {_type, {type_tags, _, _, _}} -> length(List.flatten type_tags) end)
                type
        end
    end

    defp match_tags(tags, {key, value}) do
        case tags do
            %{^key => ^value} -> true
            _ -> false
        end
    end

    defp match_tags(tags, {key}) do
        case tags do
            %{^key => _} -> true
            _ -> false
        end
    end

    def layer(type, types) do
        %{^type => {_, layer, _, _}} = types
        layer
    end

    def priority(type, types) do
        %{^type => {_, _, priority, _}} = types
        priority
    end

    def tile_index(type, types) do
        %{^type => {_, _, _, tile_index}} = types
        tile_index
    end
end