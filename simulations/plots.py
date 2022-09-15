"""
Code for making maps and other plots for aftershock detection.

"""

import pygmt
import numpy as np

from obspy.core.event import Catalog, Event
from obspy.core.inventory import Inventory


def aftershock_map(
    catalog: Catalog,
    mainshock: Event,
    inventory: Inventory = None,
    pad: float = 10.0, 
    width: float = 15.,
    mainshock_size: float = 0.7,
    inset_multiplier: float = 8,
    topo_res: str = None,
    topo_cmap: str = "geo",
    hillshade: bool = False,
) -> pygmt.Figure:
    """
    Make a basic aftershock map.
    
    Arguments
    ---------
    catalog:
        Events to plots, scaled by magnitude and colored by depth
    mainshock:
        Mainshock to plot as a gold star
    pad:
        Longitude and latitude pad as percentage of range of latitude and longitude
    width:
        Figure width in cm
    mainshock_size:
        Mainshock glyph size in cm
    inset_multiplier:
        Multiplier for inset map bounds
    topo_res:
        Topography grid resolution - leave set to None to not plot topography, set to True
        to work out resolution, or provide a reolution from here: 
        https://www.generic-mapping-tools.org/remote-datasets/earth-relief.html#id1
    topo_cmap:
        Colormap to use for topography - see https://docs.generic-mapping-tools.org/6.2/cookbook/cpts.html for names
    hillshade:
        Whether to plot hillshade or not.
    """
    lats = np.array([(ev.preferred_origin() or ev.origins[-1]).latitude for ev in catalog])
    lons = np.array([(ev.preferred_origin() or ev.origins[-1]).longitude for ev in catalog])
    depths = np.array([(ev.preferred_origin() or ev.origins[-1]).depth / 1000. for ev in catalog])
    mags = np.array([(ev.preferred_magnitude() or ev.magnitudes[-1]).mag for ev in catalog])
    times = np.array([(ev.preferred_origin() or ev.origins[-1]).time.datetime for ev in catalog])
    
    if inventory:
        station_lats = np.array([sta.latitude for net in inventory for sta in net])
        station_lons = np.array([sta.longitude for net in inventory for sta in net])
    else:
        station_lats, station_lons = np.array([]), np.array([])
        
    
    fig = _eq_map(
        lats=lats, 
        lons=lons, 
        depths=depths, 
        mags=mags, 
        times=times,
        station_lons=station_lons,
        station_lats=station_lats,
        width=width, 
        pad=pad,
        inset_multiplier=inset_multiplier,
        topo_res=topo_res,
        topo_cmap=topo_cmap,
        hillshade=hillshade,
    )
    
    # Plot mainshock
    mainshock_origin = mainshock.preferred_origin() or mainshock.origins[-1]
    fig.plot(
        x=mainshock_origin.longitude, 
        y=mainshock_origin.latitude, 
        style=f"a{mainshock_size}c", 
        color="gold", 
        pen="black"
    )
    
    return fig


def _eq_map(
    lats: np.ndarray,
    lons: np.ndarray,
    depths: np.ndarray,
    mags: np.ndarray,
    times: np.ndarray,
    station_lats: np.ndarray,
    station_lons: np.ndarray,
    pad: float,
    width: float,
    inset_multiplier: float,
    topo_res: float,
    topo_cmap: str,
    hillshade: bool,
) -> pygmt.Figure:
    """
    """
    all_lons = np.concatenate([lons, station_lons])
    all_lats = np.concatenate([lats, station_lats])
    lat_range = all_lats.max() - all_lats.min()
    lon_range = all_lons.max() - all_lons.min()
    
    region = [
        all_lons.min() - (lon_range * (pad / 100)),
        all_lons.max() + (lon_range * (pad / 100)),
        min(90, all_lats.min() - (lon_range * (pad / 100))),
        max(-90, all_lats.max() + (lon_range * (pad / 100)))
    ]
    # Work out resolution for topography
    plot_topo = True
    if topo_res is (None or False):
        plot_topo = False
    elif topo_res is True:
        min_region_dim = min(region[1] - region[0], region[3] - region[2])
        if min_region_dim > 10:
            topo_res = "01d"
        elif min_region_dim > 2:
            topo_res = "01m"
        elif min_region_dim > 0.5:
            topo_res = "15s"
        elif min_region_dim > 0.01:
            topo_res = "03s"
        else:
            topo_res = "01s"
    
    fig = pygmt.Figure()
    fig.basemap(region=region, projection=f"M{width}c", frame=True)
    
    grid = pygmt.datasets.load_earth_relief(resolution=topo_res, region=region)
    if hillshade:
        dgrid = pygmt.grdgradient(grid=grid, radiance=[0, 80], normalize=True)
        # pygmt.makecpt(cmap=topo_cmap, series=[-1.5, 0.3, 0.01])
        fig.grdimage(grid=grid, shading=dgrid, cmap=topo_cmap)
    else:
        fig.grdimage(grid=grid, cmap=topo_cmap)
    fig.coast(shorelines="1/0.5p")
    
    pygmt.makecpt(cmap="plasma", series=[depths.min(), depths.max()])
    
    # Plot earthquakes
    fig.plot(
        x=lons,
        y=lats,
        size=0.02 * 2 ** mags,
        color=depths,
        cmap=True,
        style="cc",
        pen="black"
    )
    fig.colorbar(frame='af+l"Depth (km)"')
    
    # Plot stations
    if len(station_lons) and len(station_lats):
        fig.plot(
            x=station_lons,
            y=station_lats,
            style="i0.5c",
            color="royalblue",
            pen="black",
        )
    
    inset_region = [
        region[0] - (region[1] - region[0]) * inset_multiplier,
        region[1] + (region[1] - region[0]) * inset_multiplier,
        min(90, region[2] - (region[3] - region[2]) * inset_multiplier),
        max(-90, region[3] + (region[3] - region[2]) * inset_multiplier),
    ]
    
    inset_width = round(width * 0.3, 1)
    
    max_dim = max(inset_region[1] - inset_region[0], inset_region[3] - inset_region[2])
    inset_mid_lon = inset_region[0] + (inset_region[1] - inset_region[0]) / 2
    inset_mid_lat = inset_region[2] + (inset_region[3] - inset_region[2]) / 2
    
    if max_dim > 15:
        # Orthographic projection
        inset_proj = f"G{inset_mid_lon}/{inset_mid_lat}/{inset_width}c"
    elif max_dim > 3:
        # Albers
        inset_proj = f"B{inset_mid_lon}/{inset_mid_lat}/{region[2]}/{region[3]}/{inset_width}c"
    else:
        # Mercator
        inset_proj = f"M{inset_width}c"
    
    with fig.inset(position=f"jBL+w{inset_width}c+o0.1c"):
        fig.coast(
            region=inset_region,
            projection=inset_proj,
            land="gray",
            water="white",
        )
        rectangle = [[region[0], region[2], region[1], region[3]]]
        fig.plot(data=rectangle, style="r+s", pen="2p,red", projection=inset_proj)

    
    return fig
                  