defmodule MapTileRenderer.MapData.TypeTest do
    use ExUnit.Case

    @types %{
        :forest => {[{"landuse", "forest"}, {"natural", "wood"}], 0, 1, 0},
        :road => {[{"highway"}], 0, 1, 0},
        :radio_tower => {[[{"building", "tower"}, {"tower", "communication"}]], 0, 1, 0},
        :comms_tower => {[[{"tower", "communication"}]], 0, 1, 0}
    }

    test "correctly determines type from tags" do
        assert :forest = MapTileRenderer.MapData.Type.type(%{"landuse" => "forest"}, @types)
    end

    test "matches on other tag than first" do
        assert :forest = MapTileRenderer.MapData.Type.type(%{"natural" => "wood"}, @types)
    end

    test "matches with wildcard" do
        assert :road = MapTileRenderer.MapData.Type.type(%{"highway" => "yes"}, @types)
    end

    test "matches on multiple tags with most specific type" do
        assert :radio_tower = MapTileRenderer.MapData.Type.type(%{"building" => "tower", "tower" => "communication"}, @types)
    end

    test "does not match if not all tags in a group are set" do
        assert :empty = MapTileRenderer.MapData.Type.type(%{"building" => "tower"}, @types)
    end
    
    test "gives empty type if not found" do
        assert :empty = MapTileRenderer.MapData.Type.type(%{"natural" => "water"}, @types)
    end
end