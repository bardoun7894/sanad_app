from PIL import Image, ImageDraw
import numpy as np

img_path = '/Users/mohamedbardouni/.gemini/antigravity/brain/3d7a244a-fd86-4356-b580-87ca8aaa8d58/media__1772399956483.png'
img = Image.open(img_path).convert("RGBA")
width, height = img.size

# Extract background color to ensure we get it right
bg_color = img.getpixel((0, 0))

# Crop out the slogan (bottom 35%)
crop_box = (0, 0, width, int(height * 0.65))
img_cropped = img.crop(crop_box)

# Now, we want to find the bounding box of the actual white logo (text + icon)
# to center our circle exactly around it.
data = np.array(img_cropped)
r, g, b, a = data.T
tolerance = 50
bg_r, bg_g, bg_b = bg_color[:3]
# Mask is True where it is NOT background (i.e. it's the logo)
mask = ~((abs(r - bg_r) < tolerance) & (abs(g - bg_g) < tolerance) & (abs(b - bg_b) < tolerance))

# Find the bounding box of the True values in the mask
y_indices, x_indices = np.where(mask.T)
if len(x_indices) > 0 and len(y_indices) > 0:
    min_x, max_x = np.min(x_indices), np.max(x_indices)
    min_y, max_y = np.min(y_indices), np.max(y_indices)
else:
    min_x, max_x = 0, img_cropped.width
    min_y, max_y = 0, img_cropped.height

# Logo dimensions
logo_w = max_x - min_x
logo_h = max_y - min_y
center_x = min_x + logo_w // 2
center_y = min_y + logo_h // 2

# We want our circle to encompass the logo with some padding.
padding = int(max(logo_w, logo_h) * 0.2)
radius = int((max(logo_w, logo_h) / 2) + padding)

# Create a square image that will be our final circular logo
box_size = radius * 2
# Create a new image with transparent background
final_img = Image.new('RGBA', (box_size, box_size), (0, 0, 0, 0))

# Create a circular mask
mask_img = Image.new('L', (box_size, box_size), 0)
draw = ImageDraw.Draw(mask_img)
draw.ellipse((0, 0, box_size, box_size), fill=255)

# Extract the square region from the cropped image around the logo center
# We need to create a Teal background square first, in case the bounding box goes out of bounds
teal_bg = Image.new('RGBA', (box_size, box_size), bg_color)

# Paste the cropped image onto the teal background, aligning centers
paste_x = box_size // 2 - center_x
paste_y = box_size // 2 - center_y
teal_bg.paste(img_cropped, (paste_x, paste_y))

# Apply the circular mask to the teal background
final_img = Image.composite(teal_bg, final_img, mask_img)

# Save the outputs
# Save as logo.png and logo_transparent.png. They are identical since it's a circle on transparent.
final_img.save('assets/images/logo.png')
final_img.save('assets/images/logo_transparent.png')
final_img.save('assets/images/logo_transparent_high_quality.png')

print("Circular logos saved successfully!")
