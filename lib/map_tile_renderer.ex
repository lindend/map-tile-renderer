defmodule MapTileRenderer do
    require Logger

    import ExProf.Macro

    def run_profile do
        profile do
            run
        end
    end

    def run_measure do
        t = (&run/0)
        |> :timer.tc
        |> elem(0)
        |> Kernel./(1000000)

        IO.puts("Time: #{t}s")
    end

    def run() do
        Logger.info("Parsing OSM file")
        osm_elements = OsmParse.parse("C:/temp/maps/gothenburg.pbf")
        Logger.info("Reading map data")
        data = MapTileRenderer.MapData.read_osm(osm_elements)

        Logger.info("Rasterizing tiles")
        MapRasterizer.rasterize(data, 1000, 1000, 1)
        |> Stream.map(&MapTileRenderer.TileRenderer.render/1)
        |> Stream.map(&MapTileRenderer.TileCompresser.compress(&1, 1000, 1000, 1))
        |> Stream.with_index
        |> Stream.map(fn {chunk, index} ->
            Logger.info("Writing chunk to file #{index}")
            {:ok, f} = File.open("tile_#{index}.bin", [:write])
            IO.binwrite(f, chunk)
        end)
        |> Stream.run
    end
end
