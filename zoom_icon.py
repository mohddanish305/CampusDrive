from PIL import Image
import sys

def zoom_image(input_path, output_path, zoom_factor=1.2):
    try:
        img = Image.open(input_path)
        width, height = img.size
        
        # Calculate crop dimensions
        new_width = width / zoom_factor
        new_height = height / zoom_factor
        
        left = (width - new_width) / 2
        top = (height - new_height) / 2
        right = (width + new_width) / 2
        bottom = (height + new_height) / 2
        
        # Crop the image
        img_cropped = img.crop((left, top, right, bottom))
        
        # Resize back to original size (optional, but good for consistency)
        img_resized = img_cropped.resize((width, height), Image.Resampling.LANCZOS)
        
        img_resized.save(output_path)
        print(f"Successfully zoomed image saved to {output_path}")
    except Exception as e:
        print(f"Error zooming image: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python zoom_icon.py <input_path> <output_path> [zoom_factor]")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    zoom_factor = float(sys.argv[3]) if len(sys.argv) > 3 else 1.2
    
    zoom_image(input_path, output_path, zoom_factor)
