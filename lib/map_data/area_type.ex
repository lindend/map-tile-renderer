defmodule MapTileRenderer.MapData.AreaType do
    require Logger

    @tile_types %{
        #Layer 0
        :land => {[], 0, 100, 1},
        :water => {[{"natural", "water"}, {"waterway", "riverbank"}], 0, 0, 2},
        :grass => {[{"landuse", "grass"}], 0, 4, 3},
        :forest => {[{"landuse", "forest"}, {"natural", "wood"}], 0, 1, 4},
        :sand => {[{"natural", "sand"}], 0, 2, 20},
        :wetland => {[{"natural", "wetland"}], 0, 3, 21},

        :park => {[{"leisure", "park"}], 0, 5, 22},

        :construction => {[{"landuse", "construction"}], 0, 6, 23},

        #Layer 1
        :scrub => {[{"natural", "scrub"}], 1, 0, 24},
        :rocks => {[{"natural", "bare_rock"}], 1, 0, 25},

        :railway => {[{"landuse", "railway"}], 1, 0, 26},
        :transport_platform => {[{"public_transport", "platform"}], 1, 0, 27},

        :pier => {[{"man_made", "pier"}], 1, 0, 28},

        :playground => {[{"leisure", "playground"}], 1, 0, 29},
        :garden => {[{"leisure", "garden"}, {"residential", "garden"}], 1, 0, 30},
        :pitch => {[{"leisure", "pitch"}], 1, 0, 31},
        
        :parking => {[{"amenity", "parking"}, {"amenity", "bicycle_parking"}, {"amenity", "motorcycle_parking"}], 1, 0, 32},

        :square => {[{"highway", "pedestrian"}], 1, 0, 33},
        :sidewalk => {[{"highway", "footway"}], 1, 0, 34},

        #Layer 2
        :building => {[{"building"}, {"building:part"}], 2, 0, 5},

        #Layer 3
        :bridge => {[{"man_made", "bridge"}], 3, 0, 35},
        :tunnel => {[{"man_made", "tunnel"}], 3, 0, 36},
    }


    def type(tags) do
        MapTileRenderer.MapData.Type.type(tags, @tile_types)
    end

    def layer(type) do
        MapTileRenderer.MapData.Type.layer(type, @tile_types)
    end

    def priority(type) do
        MapTileRenderer.MapData.Type.priority(type, @tile_types)
    end

    def tile_index(type) do
        MapTileRenderer.MapData.Type.tile_index(type, @tile_types)
    end

end