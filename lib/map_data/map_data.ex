defmodule MapTileRenderer.MapData do
    require Logger

    defmodule Area do
        defstruct id: 0, type: :land, tags: %{}, vertices: [], bbox: {{0.0, 0.0}, {0.0, 0.0}}
    end

    defmodule Line do
        defstruct id: 0, type: :road, tags: %{}, vertices: [], bbox: {{0.0, 0.0}, {0.0, 0.0}}
    end

    defmodule Point do
        defstruct id: 0, type: :none, tags: %{}, position: {0.0, 0.0}
    end

    defmodule MultiArea do
        defstruct id: 0, tags: %{}, areas: []
    end

    @doc """
    Streams the osm_data input and parses it into Areas, Lines and Points.
    """
    def read_osm(osm_data) do
        elements_table = :ets.new(:osm_nodes, [:set, :private])
        Stream.map(osm_data, fn %{id: id} = osm_element ->
            :ets.insert(elements_table, {id, osm_element})
            case osm_element do
                %{tags: tags} when tags == %{} -> nil
                _ -> read_element(osm_element, elements_table)
            end
        end)
        |> Enum.filter(fn element -> 
            case element do
                nil -> false
                %{type: :empty} -> false
                _ -> true
            end
        end)
    end

    defp read_element(%OsmParse.OsmNode{id: id, tags: tags, lat: lat, lon: lon}, _elements_table) do
        %Point{id: id, tags: tags, position: {lon, lat}}
    end

    defp read_element(%OsmParse.OsmWay{id: id, node_ids: node_ids, tags: tags} = way, elements_table) do
        {way_nodes, first_last} = lookup_elements(node_ids, elements_table)
        {way_vertices, bbox} = nodes_to_vertices way_nodes
        case way_type(way, first_last) do
            {:area, type} -> %Area{id: id, type: type, tags: tags, vertices: way_vertices, bbox: bbox}
            {:line, type} -> %Line{id: id, type: type, tags: tags, vertices: way_vertices, bbox: bbox}
        end
    end

    defp read_element(%OsmParse.OsmRelation{id: id, members: members, type: "multipolygon", tags: tags}, elements_table) do
        way_ids = Enum.map(members, fn %OsmParse.OsmMember{type: "way", id: id} -> id end)
        {ways, _} = lookup_elements(way_ids, elements_table)

        default_type = area_type(tags)

        areas = Enum.map(ways, &read_element(&1, elements_table))
        |> Enum.map(fn area ->
            case area do
                %{type: :empty} -> %{area | type: default_type}
                _ -> area
            end
        end)
        %MultiArea{id: id, tags: tags, areas: areas}
    end

    defp read_element(_, _) do
        nil
    end

    defp nodes_to_vertices(way_nodes) do
        %{lon: min_x = max_x, lat: min_y = max_y} = hd way_nodes
        Enum.map_reduce(way_nodes, {{min_x, min_y}, {max_x, max_y}},
            fn %OsmParse.OsmNode{lat: lat, lon: lon}, {{min_x, min_y}, {max_x, max_y}} -> 
                {{lon, lat}, {{min(min_x, lon), min(min_y, lat)}, {max(max_x, lon), max(max_y, lat)}}}
            end)
    end

    defp way_type(%OsmParse.OsmWay{tags: %{"area" => "yes"} = tags}, _), do: {:area, area_type(tags)}
    defp way_type(%{tags: tags} = way, {first_node, last_node}) when first_node == last_node do
        case way do
            %OsmParse.OsmWay{tags: %{"highway" => _}} -> {:line, line_type(tags)}
            %OsmParse.OsmWay{tags: %{"barrier" => _}} -> {:line, line_type(tags)}
            _ -> {:area, area_type(tags)}
        end
    end
    defp way_type(%{tags: tags}, _), do: {:line, line_type(tags)}

    defp line_type(tags) do
        MapTileRenderer.MapData.LineType.type(tags)
    end

    defp area_type(tags) do
        MapTileRenderer.MapData.AreaType.type(tags)
    end

    defp lookup_elements(element_ids, elements_table) do
        {elements, last_id} = Enum.map_reduce(element_ids, {[], 0}, fn(element_id, _) ->
            case :ets.lookup(elements_table, element_id) do
                [{^element_id, element}] ->
                    {element, element_id}
                any ->
                    #Logger.error "unable to find element #{element_id} (found #{inspect any})"
                    {nil, element_id}
            end
        end)
        {Enum.filter(elements, fn element -> element != nil end), {hd(element_ids), last_id}}
    end
end