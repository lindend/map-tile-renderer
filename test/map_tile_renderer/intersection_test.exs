defmodule IntersectionTest do
    use ExUnit.Case
    doctest MapTileRenderer.Intersection

    alias MapTileRenderer.Intersection

    @triangle [{0, 0}, {1, 0}, {0, 1}]
    @square [{0, 0}, {1, 0}, {1, 1}, {0, 1}]


    test "finds point inside triangle" do
        assert Intersection.point_inside_polygon?({0.1, 0.1}, @triangle)
    end

    test "excludes point outside triangle" do
        assert !Intersection.point_inside_polygon?({1, 1}, @triangle)
    end

    test "finds point in all corners of square" do
        assert Intersection.point_inside_polygon?({0.1, 0.1}, @square)
        assert Intersection.point_inside_polygon?({0.9, 0.1}, @square)
        assert Intersection.point_inside_polygon?({0.9, 0.9}, @square)
        assert Intersection.point_inside_polygon?({0.1, 0.9}, @square)
    end
end