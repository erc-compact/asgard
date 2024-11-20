#!/usr/bin/env python3

import numpy as np
from matplotlib import pyplot as plt
from matplotlib.patches import Ellipse
from astropy import wcs
from astropy.coordinates import SkyCoord
from astropy import units as u
import pandas as pd
import sys, argparse, os
from matplotlib import cm
from matplotlib.colors import Normalize

def parse_argument():

    parser = argparse.ArgumentParser()

    #parser.add_argument('--output', help='output filename for the snr plot')
    parser.add_argument('--tiling',  help='file for the coordinates of the beams')
    parser.add_argument('--beam_size_scaling', nargs=1, metavar="scaling", help='scaling factor for the size of the beam')
    parser.add_argument("--flip", action="store_true", help='flip the orientation of the beam')
    parser.add_argument("--source",  help='Source name')

    args = parser.parse_args()

    return args

args = parse_argument()

coord_file = args.tiling
if args.beam_size_scaling is not None:
    scaling = float(args.beam_size_scaling[0])
else:
    scaling = 1.0

df_coord_file =  pd.read_csv(coord_file)
ra = df_coord_file['ra'].values
dec = df_coord_file['dec'].values
beam_name = df_coord_file['name'].values
beam_shape_x = df_coord_file['x'].values
beam_shape_y = df_coord_file['y'].values
beam_shape_angle = df_coord_file['angle'].values
snr = df_coord_file['snr'].values
source_name = args.source

# Create a colormap and normalize the SNR values
norm = Normalize(vmin=min(snr), vmax=max(snr))
cmap = cm.viridis  

equatorialCoordinates = SkyCoord(ra, dec, frame='fk5', unit=(u.hourangle, u.deg))
equatorialCoordinates = np.array([equatorialCoordinates.ra.astype(float), equatorialCoordinates.dec.astype(float)]).T

boresight_ra = ra[0]
boresight_dec = dec[0]

axis1, axis2, angle = (beam_shape_x*scaling, beam_shape_y*scaling,
        180-beam_shape_angle if args.flip else beam_shape_angle)
equatorialBoresight = SkyCoord(boresight_ra, boresight_dec, frame='fk5', unit=(u.hourangle, u.deg))
boresight = (equatorialBoresight.ra.deg , equatorialBoresight.dec.deg)
basename = os.path.basename(coord_file)
fileName = basename.replace("pdmp_snr.csv", "pdmp_snr_map.png")


index = True

step = 1/10000000000.
wcs_properties = wcs.WCS(naxis=2)
wcs_properties.wcs.crpix = [0, 0]
wcs_properties.wcs.cdelt = [-step, step]
wcs_properties.wcs.crval = boresight
wcs_properties.wcs.ctype = ["RA---TAN", "DEC--TAN"]

center = boresight
resolution = step
inner_idx = []
width = 3200
thisDPI = 300
fig = plt.figure(figsize=(width/thisDPI, width/thisDPI), dpi=thisDPI)

axis = fig.add_subplot(111,aspect='equal', projection=wcs_properties)


scaled_pixel_coordinates = wcs_properties.wcs_world2pix(equatorialCoordinates, 0)
beam_coordinate = np.array(scaled_pixel_coordinates)


for idx in range(len(beam_coordinate)):
    coord = beam_coordinate[idx]
    color = cmap(norm(snr[idx]))
    ellipse = Ellipse(xy=coord,
            width=2.*axis1[idx]/resolution,height=2.*axis2[idx]/resolution, angle=angle[idx], facecolor=color, edgecolor='black')
    axis.add_artist(ellipse)


# Add a colorbar to the plot
sm = cm.ScalarMappable(cmap=cmap, norm=norm)
sm.set_array([])  # Dummy array for the colorbar
cbar = plt.colorbar(sm, ax=axis, orientation="vertical", pad=0.02)
cbar.set_label("SNR", size=20)
cbar.ax.tick_params(labelsize=15)

margin = 1.1 * max(np.sqrt(np.sum(np.square(beam_coordinate), axis=1)))
axis.set_xlim(center[0]-margin, center[0]+margin)
axis.set_ylim(center[1]-margin, center[1]+margin)


ra = axis.coords[0]
dec = axis.coords[1]
ra.set_ticklabel(size=20)
dec.set_ticklabel(size=20, rotation="vertical")
ra.set_axislabel("RA", size=20)
dec.set_axislabel("DEC", size=20)
plt.title(source_name, size=20)
plt.tight_layout()
plt.title(f"{source_name} PDMP SNR Distribution", size=20)
plt.savefig(fileName, dpi=300)
plt.close()