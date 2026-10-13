import docx
import sys
import os

def extract_text(file_path):
    try:
        doc = docx.Document(file_path)
        full_text = []
        for para in doc.paragraphs:
            full_text.append(para.text)
        return '\n'.join(full_text)
    except Exception as e:
        return f"Error: {str(e)}"

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Set stdout to UTF-8 to avoid UnicodeEncodeError on Windows
        sys.stdout.reconfigure(encoding='utf-8')
        print(extract_text(sys.argv[1]))
