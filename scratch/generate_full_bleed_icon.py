import math
from PIL import Image

def generate_full_bleed_icon():
    width = 1024
    height = 1024
    bg = Image.new("RGBA", (width, height))
    
    # Official radial gradient parameters from Logo/tremble_icon_clean.svg
    # Radial gradient from #F95B82 (0%) to #E12F58 (100%)
    # cx=50%, cy=35%, r=75%
    cx = width * 0.5
    cy = height * 0.35
    r_max = width * 0.75
    
    c1 = (249, 91, 130) # #F95B82
    c2 = (225, 47, 88)  # #E12F58
    
    print("Generating radial gradient background...")
    for y in range(height):
        for x in range(width):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx*dx + dy*dy)
            ratio = min(dist / r_max, 1.0)
            
            # Linear interpolation of RGB colors
            r = int(c1[0] + (c2[0] - c1[0]) * ratio)
            g = int(c1[1] + (c2[1] - c1[1]) * ratio)
            b = int(c1[2] + (c2[2] - c1[2]) * ratio)
            bg.putpixel((x, y), (r, g, b, 255))
            
    print("Loading transparent logo artwork...")
    logo = Image.open("Logo/tremble_icon_clean_transparent.png").convert("RGBA")
    
    print("Compositing artwork over full-bleed background...")
    final_img = Image.alpha_composite(bg, logo)
    
    # Save as RGB to remove alpha channel, as Apple guidelines recommend no transparency in App Store icons
    output_path = "Logo/tremble_icon_clean_full_bleed.png"
    final_img.convert("RGB").save(output_path, "PNG")
    print(f"Saved full-bleed brand-accurate launcher icon to: {output_path}")

if __name__ == "__main__":
    generate_full_bleed_icon()
