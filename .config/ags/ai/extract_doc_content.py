#!/usr/bin/env python
import sys
import textract
import os
import logging
import datetime

# Setup logging
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(SCRIPT_DIR, f"extract_doc_content_{datetime.datetime.now().strftime('%Y-%m-%d')}.log")

try:
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(LOG_FILE),
            # logging.StreamHandler(sys.stderr) # Uncomment to also print to stderr
        ]
    )
    logger = logging.getLogger(__name__)
    logger.info("Logging initialized successfully.") # Test log message
except Exception as e_log_setup:
    print(f"Error setting up logging: {e_log_setup}", file=sys.stderr)
    # Fallback to a dummy logger or exit if logging is critical
    class DummyLogger:
        def info(self, msg, *args, **kwargs): print(f"INFO: {msg}", file=sys.stderr)
        def error(self, msg, *args, **kwargs): print(f"ERROR: {msg}", file=sys.stderr)
        def warning(self, msg, *args, **kwargs): print(f"WARNING: {msg}", file=sys.stderr)
    logger = DummyLogger()

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
        logger.error("Usage: python extract_doc_content.py <file_path>")
        sys.exit(1)

    file_path = sys.argv[1]

    if not os.path.exists(file_path):
        logger.error(f"File not found at {file_path}")
        sys.exit(1)

    extracted_text = None
    error_message = None

    # Attempt 1: Use textract (should handle many doc types and images if tesseract is configured)
    try:
        text_bytes = textract.process(file_path)
        extracted_text = text_bytes.decode('utf-8').strip()
    except Exception as e_textract:
        error_message = f"textract failed: {str(e_textract)}"
        logger.error(f"Textract processing failed for {file_path}: {e_textract}", exc_info=True)
        # Attempt 2: If textract failed and it's an image, try pytesseract directly
        if is_image_file(file_path):
            if pytesseract and Image:
                try:
                    extracted_text = pytesseract.image_to_string(Image.open(file_path)).strip()
                    error_message = None # Clear previous error if pytesseract succeeded
                except Exception as e_ocr:
                    ocr_error_detail = f"Pytesseract OCR failed: {str(e_ocr)}. Ensure tesseract-ocr is installed and in PATH."
                    error_message += f"\n{ocr_error_detail}"
                    logger.error(f"Pytesseract OCR failed for {file_path}: {e_ocr}", exc_info=True)
            elif not pytesseract:
                 pt_error = "Pytesseract library not found, cannot perform direct OCR."
                 error_message += f"\n{pt_error}"
                 logger.warning(pt_error)
            elif not Image:
                 pil_error = "Pillow (PIL) library not found, cannot perform direct OCR."
                 error_message += f"\n{pil_error}"
                 logger.warning(pil_error)
        # If textract failed and it's not an image, the error_message from textract is the primary issue.
        # No specific fallback for non-image types beyond textract's capabilities here.
        pass # error_message already holds the textract error

    if extracted_text:
        logger.info(f"Successfully extracted text from {os.path.basename(file_path)}.")
        print(extracted_text)
    elif error_message: # If textract or OCR failed, log the detailed error
        final_error_msg = f"Error processing file {os.path.basename(file_path)}: {error_message}"
        logger.error(final_error_msg)
        # Still print to stderr so apiwidgets.js can capture it for display in UI
        print(final_error_msg, file=sys.stderr)
        sys.exit(1)
    else: # Should not happen if error_message is always set on failure
        unknown_error_msg = f"Error: Failed to extract content from {os.path.basename(file_path)}. Unknown error or empty content."
        logger.error(unknown_error_msg)
        # Still print to stderr
        print(unknown_error_msg, file=sys.stderr)
        sys.exit(1)