defmodule MapTileRenderer.TileRendererTest do
    use ExUnit.Case

    import MapTileRenderer.TileRenderer

    @land_area %{{0, 0} => [:land], {0, 1} => [:land]}

    @grass_area %{{0, 0} => [:grass], {0, 1} => [:land]}

    @prio_area %{{0,0} => [:water, :land], {0, 1} => [:land]}

    @layered_area %{{0,0} => [:water, :land, :building], {0, 1} => [:land]}

    test "renders an area with just land" do
        assert [[1], [1]] = render @land_area
    end

    test "renders a grass area" do
        assert [[3], [1]] = render @grass_area
    end

    test "properly prioritizes types" do
        assert [[2], [1]] = render @prio_area
    end

    test "renders different layers of the map" do
        assert [[2, 5], [1]] = render @layered_area
    end
end