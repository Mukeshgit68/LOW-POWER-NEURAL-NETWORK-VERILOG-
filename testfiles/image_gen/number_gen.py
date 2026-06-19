"""
MNIST to Q15.16 Hex File Generator
Generates 32-bit Q15.16 fixed-point hex files from MNIST dataset
"""

import os
import numpy as np
import torchvision.datasets as datasets
import torchvision.transforms as transforms

# ============================================================================
# CONFIGURATION
# ============================================================================

OUTPUT_DIR = "mnist_hex_files"
MAX_SAMPLES_PER_DIGIT = 10          # Number of samples per digit (0-9)
IMAGE_SIZE = 28                      # MNIST images are 28x28
PIXEL_COUNT = IMAGE_SIZE * IMAGE_SIZE  # 784 pixels

# Fixed-point format: Q15.16
FRACTIONAL_BITS = 16
TOTAL_BITS = 32

# ============================================================================
# FIXED-POINT CONVERSION
# ============================================================================

def float_to_q15_16(value):
    """
    Convert float to Q15.16 fixed-point format (32-bit)
    """
    # Scale by 2^16 (65536)
    scaled = int(round(value * (1 << FRACTIONAL_BITS)))
    
    # Clamp to 32-bit signed range
    max_val = (1 << (TOTAL_BITS - 1)) - 1
    min_val = -(1 << (TOTAL_BITS - 1))
    scaled = max(min_val, min(max_val, scaled))
    
    # Convert to unsigned 32-bit for hex representation
    if scaled < 0:
        scaled = (1 << TOTAL_BITS) + scaled
    
    return scaled

def q15_16_to_hex(value):
    """
    Convert Q15.16 value to 8-character hex string
    """
    return f"{value:08X}"

# ============================================================================
# MAIN FUNCTION
# ============================================================================

def main():
    # Create output directory
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"Created directory: {OUTPUT_DIR}")
    
    # Load MNIST dataset
    print("Loading MNIST dataset...")
    dataset = datasets.MNIST(
        root='./data',
        train=True,
        download=True,
        transform=transforms.ToTensor()
    )
    
    print(f"Dataset loaded. Total images: {len(dataset)}\n")
    
    # Track samples per digit
    count_per_digit = {i: 0 for i in range(10)}
    labels_list = []
    
    # Iterate through dataset
    for idx, (image_tensor, label) in enumerate(dataset):
        # Stop if we have enough samples for all digits
        if all(count >= MAX_SAMPLES_PER_DIGIT for count in count_per_digit.values()):
            break
        
        # Skip if we have enough of this digit
        if count_per_digit[label] >= MAX_SAMPLES_PER_DIGIT:
            continue
        
        # Process image to Q15.16 format
        img_array = image_tensor.squeeze().numpy().flatten()  # (784,)
        img_q15_16 = np.array([float_to_q15_16(val) for val in img_array], dtype=np.uint32)
        
        # Generate filename
        filename = f"digit_{label}_sample_{count_per_digit[label]}.hex"
        filepath = os.path.join(OUTPUT_DIR, filename)
        
        # Write hex file
        with open(filepath, 'w', encoding='utf-8') as f:
            for pixel_value in img_q15_16:
                f.write(f"{q15_16_to_hex(pixel_value)}\n")
        
        # Store label
        labels_list.append(label)
        
        print(f"Generated: {filename}")
        count_per_digit[label] += 1
    
    # Generate labels file
    labels_filepath = os.path.join(OUTPUT_DIR, "labels.txt")
    with open(labels_filepath, 'w', encoding='utf-8') as f:
        for label in labels_list:
            f.write(f"{label}\n")
    
    print(f"\nGenerated: labels.txt")
    
    # Print summary
    print("\n" + "="*60)
    print("GENERATION COMPLETE")
    print("="*60)
    print(f"Total files: {sum(count_per_digit.values())}")
    print(f"Samples per digit: {dict(count_per_digit)}")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Format: Q15.16 (32-bit, 8 hex chars per pixel)")
    print(f"Pixels per image: {PIXEL_COUNT}")
    print("="*60)

# ============================================================================
# ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    main()