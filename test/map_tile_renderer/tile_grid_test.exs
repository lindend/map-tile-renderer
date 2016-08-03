defmodule TileGridTest do
    use ExUnit.Case

    alias MapTileRenderer.{TileGrid, Polygon}

    @test_vertices [{-1.0, 49.5}, {-1.0, 51.5}, {2.0, 51.5}, {2.0, 49.5}, {-1.0, 49.5}]

    setup do
        {:ok, tg} = TileGrid.start_link(3, 3, 50.0, 0.0, 100000, :e)
        {:ok, tile_grid: tg}
    end

    test "creates tile grid with correct parameters", %{tile_grid: tg} do
        tiles = TileGrid.get_tiles(tg)
        assert Enum.all?(Map.values(tiles), fn value -> value == [:e] end)
    end

    test "rasterizing a polygon works", %{tile_grid: tg} do
        TileGrid.render_polygon(tg, %Polygon{areas: [{:t, @test_vertices}]})
        assert %{{0, 0} => [:t, :e], {0, 1} => [:t, :e], {0, 2} => [:e], 
             {1, 0} => [:t, :e], {1, 1} => [:t, :e], {1, 2} => [:e],
             {2, 0} => [:e], {2, 1} => [:e], {2, 2} => [:e]} = TileGrid.get_tiles(tg)
    end

    test "rasterizing a polygon outside area changes no pixels", %{tile_grid: tg} do
        TileGrid.render_polygon(tg, %Polygon{areas: [{:t, Enum.map(@test_vertices, fn {x, y} -> {x, y - 1.6} end)}]})
        tiles = TileGrid.get_tiles(tg)
        assert Enum.all?(Map.values(tiles), fn value -> value == [:e] end)
    end
end
