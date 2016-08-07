defmodule MapTileRenderer.Intersection do
    def point_inside_polygon?({x, y}, vertices) do
        shifted_vertices = tl(vertices) ++ [hd(vertices)]
        {inside, _} = Enum.reduce(shifted_vertices, {false, hd vertices}, fn v1, {inside, v0} ->
            case scanline_intersection(y, v0, v1) do
                ix when is_number(x) and ix < x -> {!inside, v1}
                _ -> {inside, v1}
            end
        end)
        inside
    end

    @doc """
    Returns true if the two boxes overlap.

    ##Examples:

        iex> MapTileRenderer.Intersection.box_vs_box?({{0.0, 0.0}, {1.0, 1.0}}, {{0.5, 0.5}, {1.5, 1.5}})
        true

        iex> MapTileRenderer.Intersection.box_vs_box?({{0.0, 0.0}, {1.0, 1.0}}, {{1.5, 1.5}, {2.5, 2.5}})
        false
    """
    def box_vs_box?(box0, box1) do
        {{b0_minx, b0_miny}, {b0_maxx, b0_maxy}} = box0
        {{b1_minx, b1_miny}, {b1_maxx, b1_maxy}} = box1
        
        lines_overlap?({b0_minx, b0_maxx}, {b1_minx, b1_maxx}) && lines_overlap?({b0_miny, b0_maxy}, {b1_miny, b1_maxy})
    end

    def box_add_point(box, {px, py}) do
        {{b_minx, b_miny}, {b_maxx, b_maxy}} = box
        {{min(b_minx, px), min(b_miny, py)}, {max(b_maxx, px), max(b_maxy, py)}}
    end

    @doc """
    Returns true if the line segments overlap.

    ##Examples:

        iex> MapTileRenderer.Intersection.lines_overlap?({0.0, 1.0}, {0.5, 1.5})
        true

        iex> MapTileRenderer.Intersection.lines_overlap?({0.0, 1.0}, {0.5, 0.6})
        true

        iex> MapTileRenderer.Intersection.lines_overlap?({0.0, 1.0}, {-0.5, 1.5})
        true

        iex> MapTileRenderer.Intersection.lines_overlap?({0.0, 1.0}, {-0.5, 0.5})
        true

        iex> MapTileRenderer.Intersection.lines_overlap?({0.0, 1.0}, {1.5, 2.5})
        false

        iex> MapTileRenderer.Intersection.lines_overlap?({3.0, 4.0}, {0.5, 1.5})
        false
    """
    def lines_overlap?({p0_min, p0_max}, {p1_min, p1_max}) do
        cond do
            p0_min <= p1_min && p0_max >= p1_min -> true
            p0_min <= p1_max && p0_max >= p1_max -> true
            p0_min >= p1_min && p0_max <= p1_max -> true
            true -> false 
        end
    end

    @doc """
    Gives all intersections between the scanline (height) and the polygon formed by the vertices.

    ##Examples:

        iex> MapTileRenderer.Intersection.polygon_scanline_intersections(1, [{0, 0}, {2, 2}, {8, 0}, {10, 2}, {10, -1}])
        [10.0, 9.0, 5.0, 1.0]

        iex> MapTileRenderer.Intersection.polygon_scanline_intersections(1, [{0, 0}, {2, -1}])
        []
    """
    def polygon_scanline_intersections(scanline, vertices) do
        shifted_vertices = tl(vertices) ++ [hd(vertices)]
        {intersections, _} = Enum.reduce(shifted_vertices, {[], hd vertices}, fn v1, {intersections, v0} ->
            case scanline_intersection(scanline, v0, v1) do
                x when is_number(x) -> {[x | intersections], v1}
                _ -> {intersections, v1}
            end
        end)
        intersections
    end

    @doc """
    Returns the x coordinate of the intersection between a scanline at height y and
    a line between v0 and v1.

    ##Examples

        iex> MapTileRenderer.Intersection.scanline_intersection(0, {0, -1}, {0, 1})
        0.0

        iex> MapTileRenderer.Intersection.scanline_intersection(0.5, {1, -1}, {1, 1})
        1.0

        iex> MapTileRenderer.Intersection.scanline_intersection(1, {0, -2}, {4, 2})
        3.0

        iex> MapTileRenderer.Intersection.scanline_intersection(0, {2, 1}, {2, -1})
        2.0

        iex> MapTileRenderer.Intersection.scanline_intersection(0, {0, 2}, {0, 1})
        :no_intersection

        iex> MapTileRenderer.Intersection.scanline_intersection(1, {0, 1}, {1, 1})
        :no_intersection
    """
    def scanline_intersection(scanline, {v0x, v0y}, {v1x, v1y}) do
        cond do
            v1y - v0y == 0 -> :no_intersection
            (v1y > scanline) == (v0y > scanline) -> :no_intersection
            true -> (scanline - v0y) / (v1y - v0y) * (v1x - v0x) + v0x
        end
    end
end