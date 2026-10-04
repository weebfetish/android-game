class_name ArtAssets
extends RefCounted
## Shared textures: each category image is reused by both part cards.

const MIKA: Texture2D = preload("res://assets/characters/mika.png")
const WORKSHOP: Texture2D = preload("res://assets/backgrounds/workshop_room.png")
const PART_ICONS: Dictionary = {
	"cpu": preload("res://assets/icons/cpu.png"),
	"motherboard": preload("res://assets/icons/motherboard.png"),
	"ram": preload("res://assets/icons/ram.png"),
	"ssd": preload("res://assets/icons/ssd.png"),
	"psu": preload("res://assets/icons/psu.png"),
}


static func component_icon(category: String) -> Texture2D:
	return PART_ICONS.get(category)


static func texture_rect(texture: Texture2D, minimum_size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	# Source resolution must not force a large mobile layout.
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = minimum_size
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return image
