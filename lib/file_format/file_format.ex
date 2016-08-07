defmodule MapTileRenderer.FileFormat do
    use Protobuf, """
message TileLayer {
    //Used to signify the same tile in all cells
    optional int32 single_tile = 1;

    //Delta encoded
    repeated int32 tiles = 2;
}

message TileChunk {
    required int32 width = 1;
    required int32 height = 2;
    required int32 resolution = 3;

    repeated TileLayer tile_layers = 4 [packed = true];
}
    """
end