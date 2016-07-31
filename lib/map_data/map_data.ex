defmodule MapTileRenderer.MapData do
    defmodule Area do
        defstruct id: 0, type: :land, tags: %{}, vertices: []
    end

    defmodule Line do
        defstruct id: 0, type: :road, tags: %{}, vertices: []
    end

    defmodule Point do
        defstruct id: 0, type: :none, tags: %{}, position: {0.0, 0.0}
    end

    @doc """
    Streams the osm_data input and parses it into Areas, Lines and Points.
    """
    def read_osm(osm_data) do
        nodes_table = :ets.new(:osm_nodes, [:set, :private])
        Stream.map(osm_data, fn osm_element ->
            case osm_element do
                %OsmParse.OsmNode{id: id, tags: tags} when tags == %{} ->
                    :ets.insert(nodes_table, {id, osm_element})
                    nil
                _ -> read_element(osm_element, nodes_table)
            end
        end)
            |> Stream.filter(fn element ->
                case element do
                    nil -> false
                    _ -> true
                end
            end)
    end

    defp read_element(%OsmParse.OsmNode{id: id, tags: tags, lat: lat, lon: lon} = node, nodes_table) do
        :ets.insert(nodes_table, {id, node})
        %Point{id: id, tags: tags, position: {lat, lon}}
    end

    defp read_element(%OsmParse.OsmWay{id: id, node_ids: node_ids, tags: tags} = way, nodes_table) do
        {way_nodes, first_last} = lookup_nodes(node_ids, nodes_table)
        :ets.delete(nodes_table, node_ids)        
        way_vertices = Enum.map(way_nodes, fn %OsmParse.OsmNode{lat: lat, lon: lon} -> {lat, lon} end)

        case way_type(way, first_last) do
            :area -> %Area{id: id, tags: tags, vertices: way_vertices}
            :line -> %Line{id: id, tags: tags, vertices: way_vertices}
        end
    end

    defp read_element(_, _) do
        nil
    end

    defp way_type(%OsmParse.OsmWay{tags: %{"area" => "yes"}}, _), do: :area
    defp way_type(way, {first_node, last_node}) when first_node == last_node do
        case way do
            %OsmParse.OsmWay{tags: %{"highway" => _}} -> :line
            %OsmParse.OsmWay{tags: %{"barrier" => _}} -> :line
            _ -> :area
        end
    end
    defp way_type(_, _), do: :line

    defp lookup_nodes(node_ids, nodes_table) do
        {nodes, last_id} = Enum.map_reduce(node_ids, {[], 0}, fn(node_id, _) ->
            case :ets.lookup(nodes_table, node_id) do
                [{^node_id, node}] -> 
                    {node, node_id}
                any -> 
                    raise "unable to find node #{node_id} (found #{inspect any})"
            end
        end)
        {nodes, {hd(node_ids), last_id}}
    end
end