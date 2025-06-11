#!/usr/bin/env python
import sys
import textract
import os

# For image OCR, you might need to install pytesseract and Pillow:
# pip install pytesseract Pillow
# And ensure tesseract-ocr is installed on your system:
# Fedora: sudo dnf install tesseract tesseract-langpack-eng
# Ubuntu: sudo apt-get install tesseract-ocr tesseract-ocr-eng
# Arch: sudo pacman -S tesseract tesseract-data-eng

try:
    from PIL import Image
except ImportError:
    Image = None
    # print("Pillow library not found, image processing might be limited. pip install Pillow", file=sys.stderr)

try:
    import pytesseract
except ImportError:
    pytesseract = None
    # print("pytesseract library not found, direct OCR for images will not be available. pip install pytesseract", file=sys.stderr)

COMMON_IMAGE_EXTENSIONS = ['.png', '.jpg', '.jpeg', '.bmp', '.gif', '.tiff', '.webp']

def is_image_file(file_path):
    _, ext = os.path.splitext(file_path.lower())
    return ext in COMMON_IMAGE_EXTENSIONS

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python extract_doc_content.py <file_path>", file=sys.stderr)
        sys.exit(1)

    file_path = sys.argv[1]

    if not os.path.exists(file_path):
        print(f"Error: File not found at {file_path}", file=sys.stderr)
        sys.exit(1)

    extracted_text = None
    error_message = None

    # Attempt 1: Use textract (should handle many doc types and images if tesseract is configured)
    try:
        text_bytes = textract.process(file_path)
        extracted_text = text_bytes.decode('utf-8').strip()
    except Exception as e_textract:
        error_message = f"textract failed: {e_textract}"
        # Attempt 2: If textract failed and it's an image, try pytesseract directly
        if is_image_file(file_path):
            if pytesseract and Image:
                try:
                    extracted_text = pytesseract.image_to_string(Image.open(file_path)).strip()
                    error_message = None # Clear previous error if pytesseract succeeded
                except Exception as e_ocr:
                    error_message += f"\nPytesseract OCR failed: {e_ocr}. Ensure tesseract-ocr is installed and in PATH."
            elif not pytesseract:
                 error_message += "\nPytesseract library not found, cannot perform direct OCR."
            elif not Image:
                 error_message += "\nPillow (PIL) library not found, cannot perform direct OCR."
        else:
            error_message += "\nFile is not a recognized image type for direct OCR fallback."

    if extracted_text:
        print(extracted_text)
    else:
        final_error = f"Error processing file {file_path}."
        if error_message:
            final_error += f" Details: {error_message}"
        else:
            final_error += " Unknown error or empty content."
        print(final_error, file=sys.stderr)
        sys.exit(1)