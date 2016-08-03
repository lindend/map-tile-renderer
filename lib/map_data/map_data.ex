defmodule MapTileRenderer.MapData do
    require Logger

    defmodule Area do
        defstruct id: 0, type: :land, tags: %{}, vertices: []
    end

    defmodule Line do
        defstruct id: 0, type: :road, tags: %{}, vertices: []
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
        |> Stream.filter(fn element -> element != nil end)
    end

    defp read_element(%OsmParse.OsmNode{id: id, tags: tags, lat: lat, lon: lon}, _elements_table) do
        %Point{id: id, tags: tags, position: {lon, lat}}
    end

    defp read_element(%OsmParse.OsmWay{id: id, node_ids: node_ids, tags: tags} = way, elements_table) do
        {way_nodes, first_last} = lookup_elements(node_ids, elements_table, true)
        way_vertices = Enum.map(way_nodes, fn %OsmParse.OsmNode{lat: lat, lon: lon} -> {lon, lat} end)

        case way_type(way, first_last) do
            :area -> %Area{id: id, tags: tags, vertices: way_vertices}
            :line -> %Line{id: id, tags: tags, vertices: way_vertices}
        end
    end

    defp read_element(%OsmParse.OsmRelation{id: id, members: members, type: "multipolygon", tags: tags}, elements_table) do
        way_ids = Enum.map(members, fn %OsmParse.OsmMember{type: "way", id: id} -> id end)
        {ways, _} = lookup_elements(way_ids, elements_table, false)

        %MultiArea{id: id, tags: tags, areas: Enum.map(ways, &read_element(&1, elements_table))}
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

    defp lookup_elements(element_ids, elements_table, raise_not_found) do
        {elements, last_id} = Enum.map_reduce(element_ids, {[], 0}, fn(element_id, _) ->
            case :ets.lookup(elements_table, element_id) do
                [{^element_id, element}] ->
                    {element, element_id}
                any ->
                    Logger.error "unable to find element #{element_id} (found #{inspect any})"
                    cond do
                        raise_not_found -> raise "unable to find element #{element_id} (found #{inspect any})"
                        true -> nil
                    end
            end
        end)
        {Enum.filter(elements, fn element -> element != nil end), {hd(element_ids), last_id}}
    end
end