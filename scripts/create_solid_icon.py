from PIL import Image

def create_solid_bg_icon(input_path, output_path, bg_hex):
    # Open the image with transparency
    img = Image.open(input_path).convert("RGBA")
    
    # Create a background image
    bg = Image.new("RGBA", img.size, bg_hex)
    
    # Paste the image onto the background
    bg.paste(img, mask=img)
    
    # Save as RGB to remove alpha channel
    bg.convert("RGB").save(output_path, "PNG")

input_img = "/Users/mohamedbardouni/Downloads/sanad_app/assets/images/logo_for_splash-removebg-preview.png"
output_img = "/Users/mohamedbardouni/Downloads/sanad_app/assets/images/launcher_icon_solid.png"
background_color = "#2175A5"

try:
    create_solid_bg_icon(input_img, output_img, background_color)
    print("SUCCESS")
except Exception as e:
    print(f"FAILED: {e}")
