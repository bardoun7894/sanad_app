from PIL import Image

def remove_slogan(input_path, output_path):
    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        # The background color is a teal color, let's grab it from the center left
        bg_color = img.getpixel((50, height//2))
        
        pixels = img.load()
        # Scan bottom half, if pixel is mostly white/light and not transparent, make it bg_color
        for y in range(int(height * 0.65), height):
            for x in range(width):
                r, g, b, a = pixels[x, y]
                # Light text check
                if r > 200 and g > 200 and b > 200 and a > 0:
                    pixels[x, y] = bg_color
        
        img.save(output_path)
        print("Successfully removed slogan.")
    except Exception as e:
        print(f"Error: {e}")

remove_slogan('assets/images/logo.png', 'assets/images/logo_no_slogan.png')
