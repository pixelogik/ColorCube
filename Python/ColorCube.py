# The MIT License (MIT)

# Copyright (c) 2015 Ole Krause-Sparmann

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from PIL import Image

import math

class LocalMaximum:
	# Local maxima as found during the image analysis. 
	# We need this class for ordering by cell hit count.
	def __init__(self, hit_count, cell_index, r, g, b):
		# Hit count of the cell
		self.hit_count = hit_count
		# Linear index of the cell
		self.cell_index = cell_index
		# Average color of the cell
		self.r = r
		self.g = g
		self.b = b

class CubeCell:
	# The color cube is made out of these cells
	def __init__(self):
		# Count of hits (dividing the accumulators by this value gives the average color)
		self.hit_count = 0
		# Accumulators for color components 
		self.r_acc = 0.0
		self.g_acc = 0.0
		self.b_acc = 0.0

class ColorCube:
	# Uses a 3d RGB histogram to find local maximas in the density distribution
	# in order to retrieve dominant colors of pixel images
	def __init__(self, resolution=30, avoid_color=None, distinct_threshold=0.2, bright_threshold=0.6):
		
		# Keep resolution
		self.resolution = resolution

		# Threshold for distinct local maxima
		self.distinct_threshold = distinct_threshold

		# Color to avoid
		self.avoid_color = avoid_color

		# Colors that are darker than this go away		
		self.bright_threshold = bright_threshold

		# Helper variable to have cell count handy
		self.cell_count = resolution * resolution * resolution

		# Create cells 
		self.cells = [ CubeCell() for k in range(self.cell_count)]

		# Indices for neighbour cells in three dimensional grid
		self.neighbour_indices = [
		    [ 0, 0, 0],
		    [ 0, 0, 1],
		    [ 0, 0,-1],

		    [ 0, 1, 0],
		    [ 0, 1, 1],
		    [ 0, 1,-1],

		    [ 0,-1, 0],
		    [ 0,-1, 1],
		    [ 0,-1,-1],

		    [ 1, 0, 0],
		    [ 1, 0, 1],
		    [ 1, 0,-1],

		    [ 1, 1, 0],
		    [ 1, 1, 1],
		    [ 1, 1,-1],

		    [ 1,-1, 0],
		    [ 1,-1, 1],
		    [ 1,-1,-1],

		    [-1, 0, 0],
		    [-1, 0, 1],
		    [-1, 0,-1],

		    [-1, 1, 0],
		    [-1, 1, 1],
		    [-1, 1,-1],

		    [-1,-1, 0],
		    [-1,-1, 1],
		    [-1,-1,-1]
		]

	def cell_index(self, r, g, b):
		# Returns linear index for cell with given 3d index
		return (r+g*self.resolution+b*self.resolution*self.resolution)

	def clear_cells(self):
		for c in self.cells:
			c.hit_count = 0 
			c.r_acc = 0.0
			c.g_acc = 0.0
			c.b_acc = 0.0

	def get_colors(self, image):
		m = self.find_local_maxima(image)

		if not self.avoid_color is None:
			m = self.filter_too_similar(m)

		m = self.filter_distinct_maxima(m)

		colors = []
		for n in m:
			r = int(n.r*255.0)
			g = int(n.g*255.0)
			b = int(n.b*255.0)
			colors.append([r, g, b])

		return colors

	def find_local_maxima(self, image):
		# Finds and returns local maxima in 3d histogram, sorted with respect to hit count

		# Reset all cells
		self.clear_cells()

		# Iterate over all pixels of the image
		for p in image.getdata(): 

			# Get color components
			r = float(p[0])/255.0
			g = float(p[1])/255.0
			b = float(p[2])/255.0

			if r < self.bright_threshold and g < self.bright_threshold and b < self.bright_threshold:
				continue

			# If image has alpha channel, weight colors by it
			if len(p) == 4:
				a = float(p[3])/255.0
				r *= a
				g *= a
				b *= a

			# Map color components to cell indices in each color dimension
			r_index = int(r*(float(self.resolution)-1.0))
			g_index = int(g*(float(self.resolution)-1.0))
			b_index = int(b*(float(self.resolution)-1.0))

			# Compute linear cell index 
			index = self.cell_index(r_index, g_index, b_index)

			# Increase hit count of cell
			self.cells[index].hit_count += 1

			# Add pixel colors to cell color accumulators
			self.cells[index].r_acc += r
			self.cells[index].g_acc += g
			self.cells[index].b_acc += b

		# We collect local maxima in here
		local_maxima = []

		# Find local maxima in the grid
		for r in range(self.resolution):
			for g in range(self.resolution):
				for b in range(self.resolution):

					local_index = self.cell_index(r, g, b)

					# Get hit count of this cell
					local_hit_count = self.cells[local_index].hit_count

					# If this cell has no hits, ignore it (we are not interested in zero hit cells)
					if local_hit_count == 0: 
						continue

					# It is a local maximum until we find a neighbour with a higher hit count
					is_local_maximum = True

					# Check if any neighbour has a higher hit count, if so, no local maxima

					for n in range(27):
						r_index = r+self.neighbour_indices[n][0]
						g_index = g+self.neighbour_indices[n][1]
						b_index = b+self.neighbour_indices[n][2]

						# Only check valid cell indices (skip out of bounds indices)

						if r_index >= 0 and g_index >= 0 and b_index >= 0:
							if r_index < self.resolution and g_index < self.resolution and b_index < self.resolution:
								if self.cells[self.cell_index(r_index, g_index, b_index)].hit_count > local_hit_count:
									# Neighbour hit count is higher, so this is NOT a local maximum.
									is_local_maximum = False
									# Break inner loop
									break

				   	# If this is not a local maximum, continue with loop.
					if is_local_maximum == False:
						continue

					# Otherwise add this cell as local maximum
					avg_r = self.cells[local_index].r_acc / float(self.cells[local_index].hit_count)
					avg_g = self.cells[local_index].g_acc / float(self.cells[local_index].hit_count)
					avg_b = self.cells[local_index].b_acc / float(self.cells[local_index].hit_count)					
					local_maxima.append(LocalMaximum(local_hit_count, local_index, avg_r, avg_g, avg_b))

		# Return local maxima sorted with respect to hit count
		return sorted(local_maxima, key=lambda x: x.hit_count, reverse=True)

	def filter_distinct_maxima(self, maxima):
	   	# Returns a filtered version of the specified array of maxima, 
		# in which all entries have a minimum distance of self.distinct_threshold

		result = []

		# Check for each maximum 
		for m in maxima:
        	# This color is distinct until a color from before is too close
			is_distinct = True

			for n in result:
				# Compute delta components
				r_delta = m.r - n.r
				g_delta = m.g - n.g
				b_delta = m.b - n.b

				# Compute delta in color space distance
				delta = math.sqrt(r_delta*r_delta + g_delta*g_delta + b_delta*b_delta)

				# If too close mark as non-distinct and break inner loop
				if delta < self.distinct_threshold:
					is_distinct = False
					break

			# Add to filtered array if is distinct        	
			if is_distinct == True:
				result.append(m)
        	
		return result

	def filter_too_similar(self, maxima):
	   	# Returns a filtered version of the specified array of maxima, 
		# in which all entries are far enough away from the specified avoid_color

		result = []

		ar = float(self.avoid_color[0])/255.0
		ag = float(self.avoid_color[1])/255.0
		ab = float(self.avoid_color[2])/255.0

		# Check for each maximum 
		for m in maxima:

			# Compute delta components
			r_delta = m.r - ar
			g_delta = m.g - ag
			b_delta = m.b - ab

			# Compute delta in color space distance
			delta = math.sqrt(r_delta*r_delta + g_delta*g_delta + b_delta*b_delta)

			if delta >= 0.5:
				result.append(m)
        	
		return result

################################################################################
# Command line example
if __name__ == "__main__":
	import argparse
	parser = argparse.ArgumentParser(description='Get dominant colors of an image.')
	parser.add_argument('image', help='Image file to process.')
	args = parser.parse_args()

	# Create color cube, avoiding resulting colors that are too close to white.
	cc = ColorCube(avoid_color=[255, 255, 255])

	# Load image and scale down to make the algorithm faster.
	# Scaling down also gives colors that are more dominant in perception.
	image = Image.open(args.image).resize((50, 50))

	# Get colors for that image
	colors = cc.get_colors(image)
	
	# Print first four colors (there might be much more)
	for c in colors[:10]:
		print(c)
