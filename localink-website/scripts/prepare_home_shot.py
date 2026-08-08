from PIL import Image, ImageEnhance
from pathlib import Path
import numpy as np

src = Path(r"C:\Users\ANCHURU SANKEERTH\.cursor\projects\c-Users-ANCHURU-SANKEERTH-Internship-Project\assets\c__Users_ANCHURU_SANKEERTH_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_094ca506-ecec-4ef4-bcdd-883601bfa616-1fedd476-7b21-41b5-8fde-08869fff1b04.png")
out = Path(r"C:\Users\ANCHURU SANKEERTH\Internship-Project\localink-website\public\images\app-home.png")

im = Image.open(src).convert("RGB")
arr = np.array(im)
h, w, _ = arr.shape

# Status bar ends ~ just above profile row
top = 58
for y in range(40, 100):
    # profile avatar is dark/colorful on left
    patch = arr[y, 24:70]
    if patch.std() > 35 and patch.mean() < 180:
        top = max(0, y - 6)
        break

# Cut above floating bottom nav: look for horizontal white floating bar near bottom
# Strategy: find last contentful area before a soft shadow / white gap above nav
bottom = int(h * 0.86)
# Prefer cutting where business card still visible; nav sits ~ y 920-980 on 1024
bottom = min(bottom, 880)

cropped = im.crop((0, top, w, bottom))

# Soft edge polish + enhancement
cropped = ImageEnhance.Contrast(cropped).enhance(1.05)
cropped = ImageEnhance.Color(cropped).enhance(1.07)
cropped = ImageEnhance.Sharpness(cropped).enhance(1.12)

out.parent.mkdir(parents=True, exist_ok=True)
cropped.save(out, "PNG", optimize=True)
print(f"crop top={top} bottom={bottom} size={cropped.size} bytes={out.stat().st_size}")

