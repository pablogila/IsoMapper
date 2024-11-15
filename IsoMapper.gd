extends Node2D


# Create the scene and add the input image and the mask texture in the inspector. Run the scene to
# generate the image and it will save into the output_path


@export var input_tileset_image: Texture2D
@export var tile_mask_image: Texture2D
@export_global_dir var output_path: String

var grid_width := 4
var grid_height := 4
var tile_size := Vector2i(64, 32)
var iso_positions: Array[Vector2i] = [
	Vector2i(3, 0), Vector2i(2,1), Vector2i(1,2), Vector2i(0,3),
	Vector2i(4, 1), Vector2i(3,2), Vector2i(2,3), Vector2i(1,4),
	Vector2i(5, 2), Vector2i(4,3), Vector2i(3,4), Vector2i(2,5),
	Vector2i(6, 3), Vector2i(5,4), Vector2i(4,5), Vector2i(3,6),
]
var grid_position: Array[Vector2i] = [
	Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3),
	Vector2i(1,0), Vector2i(1,1), Vector2i(1,2), Vector2i(1,3),
	Vector2i(2,0), Vector2i(2,1), Vector2i(2,2), Vector2i(2,3),
	Vector2i(3,0), Vector2i(3,1), Vector2i(3,2), Vector2i(3,3),
]
var slices: Array[Image]
var new_image: Image


func _ready() -> void:
	build_slices()
	build_new_iamge()


func build_slices() -> void:
	# Check we have the resourcecs to do this or exit
	if not input_tileset_image:
		return
	if not tile_mask_image:
		return
	
	# Convert the resources to Image resources
	var input_image := input_tileset_image.get_image()
	var mask_image := tile_mask_image.get_image()
	
	# Could probably work the positions out by code... but why bother
	for slice_position in iso_positions:
		
		# Create an empty image the size of a tile
		var new_slice := Image.create_empty(tile_size.x, tile_size.y, false, input_image.get_format())
		
		# Blit (copy) the rect onto the new image
		var blit_position := slice_position * (tile_size / 2)
		var slice_rect := Rect2i(blit_position, Vector2i(tile_size.x, tile_size.y))
		new_slice.blit_rect(input_image, slice_rect, Vector2i(0,0))
		
		# Mask the blitted slice, needs to happen after because the size needs to be the same.
		var masked_slice := Image.create_empty(tile_size.x, tile_size.y, false, input_image.get_format())
		var mask_rect := Rect2i(Vector2i(0,0), tile_size)
		masked_slice.blit_rect_mask(new_slice, mask_image, mask_rect, Vector2i(0,0))
		
		# Add it to an array for later use
		slices.append(masked_slice)


func build_new_iamge() -> void:
	# Check we have image slice
	if slices.size() == 0:
		return
	
	# Create new image that's blank. The RGBA8 format should preserve alpha but I havent tested yet
	new_image = Image.create_empty(grid_width * tile_size.x, grid_height * tile_size.y, false, Image.FORMAT_RGBA8)
	
	# Loop through the slices to build the image in grid order. Again just using array positions for speed
	var i := 0
	for slice in slices:
		# Dst is the position on the new image, rect is the tile size
		var dst := grid_position[i] * tile_size
		var slice_rect = Rect2i(Vector2i(0,0), tile_size)
		new_image.blit_rect(slice, slice_rect, dst)
		i += 1
	
	if output_path:
		# Save to a file. You could add a filename export if you wanted to
		new_image.save_png(output_path + "/grid_tiles.png")
