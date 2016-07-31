defmodule MapTileRenderer.MapDataTeset do
    use ExUnit.Case

    doctest MapTileRenderer.MapData

    @line_nodes [%OsmParse.OsmNode{id: 1, lat: 0.0, lon: 1.0}, %OsmParse.OsmNode{id: 2, lat: 2.0, lon: 3.0}]
    @area_nodes @line_nodes ++ [%OsmParse.OsmNode{id: 3, lat: 4.0, lon: 5.0}]
    @test_tags %{"test_tag" => "test_value"}

    test "reads a node correctly" do
        result = MapTileRenderer.MapData.read_osm([%OsmParse.OsmNode{id: 1, tags: %{"test" => "test"}, lat: 0.0, lon: 1.0}]) |> Enum.to_list
        assert [%MapTileRenderer.MapData.Point{id: 1, position: {0.0, 1.0}, tags: %{"test" => "test"}}] = result
    end

    test "nodes with no tags are not returned" do
        result = MapTileRenderer.MapData.read_osm([%OsmParse.OsmNode{id: 1, tags: %{}, lat: 0.0, lon: 1.0}]) |> Enum.to_list
        assert [] = result
    end

    test "reads a way with two nodes as a line" do
        result = MapTileRenderer.MapData.read_osm(@line_nodes ++ [%OsmParse.OsmWay{id: 3, node_ids: [1, 2], tags: @test_tags}]) |> Enum.to_list
        assert [%MapTileRenderer.MapData.Line{id: 3, vertices: [{0.0, 1.0}, {2.0, 3.0}], tags: @test_tags}] = result
    end

    test "reads a closed way as an area" do
        result = MapTileRenderer.MapData.read_osm(@area_nodes ++ [%OsmParse.OsmWay{id: 4, node_ids: [1, 2, 3, 1], tags: @test_tags}]) |> Enum.to_list
        assert [%MapTileRenderer.MapData.Area{id: 4, vertices: [{0.0, 1.0}, {2.0, 3.0}, {4.0, 5.0}, {0.0, 1.0}], tags: @test_tags}] = result
    end

    test "does not read relations" do
        result = MapTileRenderer.MapData.read_osm(@area_nodes ++ [%OsmParse.OsmRelation{id: 5}]) |> Enum.to_list
        assert [] = result
    end
end