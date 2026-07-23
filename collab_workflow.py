# =============================================================================
# Colab workflow for testing the `scale` Verilog module
# Copy each "# %% CELL" block into its own Colab cell (or just run top to bottom
# in one cell if you prefer).
# =============================================================================

# %% CELL 1 - Install Icarus Verilog (iverilog + vvp) on the Colab VM
!apt-get update -qq && apt-get install -y -qq iverilog

# %% CELL 2 - Parameters (MUST match the parameters in your testbench.v!)
# Your testbench currently instantiates: .Win(4) .Hin(4) .Wout(16) .Hout(16) .CHANNELS(3)
WIN, HIN = 275, 183
WOUT, HOUT = 2160, 1800
CHANNELS = 1

# %% CELL 3 - Upload your source image
from google.colab import files
import io
from PIL import Image

print("Upload the source image you want to test (jpg/png)...")
uploaded = files.upload()
src_path = list(uploaded.keys())[0]
img = Image.open(io.BytesIO(uploaded[src_path])).convert("RGB")
print(f"Loaded {src_path}, size={img.size}")

# %% CELL 4 - Downscale to Win x Hin and write inputR/G/B.hex
import numpy as np

small = img.resize((WIN, HIN), Image.LANCZOS)   # try Image.NEAREST too, for comparison
arr = np.array(small)  # shape (HIN, WIN, 3), row-major, matches addr = y*Win + x

def write_hex(channel_arr, filename):
    with open(filename, "w") as f:
        for y in range(HIN):
            for x in range(WIN):
                f.write(f"{channel_arr[y, x]:02x}\n")

write_hex(arr[:, :, 0], "inputR.hex")
write_hex(arr[:, :, 1], "inputG.hex")
write_hex(arr[:, :, 2], "inputB.hex")

print("Wrote inputR.hex, inputG.hex, inputB.hex")
small.resize((WIN * 20, HIN * 20), Image.NEAREST)  # just for a quick visual preview

# %% CELL 5 - Upload scale.v and testbench.v (the Verilog source files)
print("Upload scale.v and testbench.v...")
uploaded_v = files.upload()
# Expect files named scale.v and testbench.v; rename if Colab gives them odd names
import os
for name in uploaded_v:
    if "testbench" in name.lower():
        os.rename(name, "testbench.v")
    elif "scale" in name.lower():
        os.rename(name, "scale.v")

# %% CELL 6 - Compile and run the simulation
!iverilog -o sim_out scale.v testbench.v
!vvp sim_out

# %% CELL 7 - Read back outputR/G/B.hex and reassemble the image
import numpy as np
from PIL import Image

def read_hex(filename, w, h):
    with open(filename) as f:
        vals = []
        for line in f:
            # Remove any trailing comments and whitespace
            clean_line = line.split('//')[0].strip()
            if clean_line:
                vals.append(int(clean_line, 16))

    if len(vals) < w * h:
        raise ValueError(f"{filename} has {len(vals)} values, expected {w*h}")
    return np.array(vals[:w*h], dtype=np.uint8).reshape(h, w)

# Use the CHANNELS variable you defined earlier in the notebook
if CHANNELS == 1:
    print("Processing as 1-Channel Grayscale...")
    # Grayscale mode: Read only the R file since it holds the grayscale data
    gray_data = read_hex("outputR.hex", WOUT, HOUT)
    out_img = Image.fromarray(gray_data, mode="L")
    out_name = "scaled_output_gray.png"

else:
    print("Processing as 3-Channel RGB...")
    # RGB mode: Read all three files and stack them
    r = read_hex("outputR.hex", WOUT, HOUT)
    g = read_hex("outputG.hex", WOUT, HOUT)
    b = read_hex("outputB.hex", WOUT, HOUT)

    out_arr = np.stack([r, g, b], axis=-1)
    out_img = Image.fromarray(out_arr, mode="RGB")
    out_name = "scaled_output_color.png"

# Save and display the final image
out_img.save(out_name)
print(f"Saved {out_name}, size={out_img.size}")

# %% CELL 8 - Display (small, so upscale with NEAREST for visibility)
display_img = out_img.resize((WOUT * 30, HOUT * 30), Image.NEAREST)
display_img
