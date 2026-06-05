import PyPDF2
import os

def extract_pdf(pdf_path, output_txt_path):
    print(f"Extracting {pdf_path} -> {output_txt_path}")
    try:
        with open(pdf_path, 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            print(f"Total pages: {len(reader.pages)}")
            with open(output_txt_path, 'w', encoding='utf-8') as out_f:
                for i, page in enumerate(reader.pages):
                    text = page.extract_text()
                    if text and text.strip():
                        # Replace problematic unicode characters
                        text = (text.replace('\u2010', '-')
                                    .replace('\u2019', "'")
                                    .replace('\u2018', "'")
                                    .replace('\u201c', '"')
                                    .replace('\u201d', '"')
                                    .replace('\u2013', '-')
                                    .replace('\u2014', '--')
                                    .replace('\u2022', '*'))
                        out_f.write(f"--- Page {i+1} ---\n")
                        out_f.write(text)
                        out_f.write("\n\n")
        print("Extraction completed successfully.")
    except Exception as e:
        print(f"Error extracting {pdf_path}: {e}")

pdf1 = r"C:\Users\jagga\.gemini\antigravity\scratch\BEYOND_THE_RIM_1_-_FREE_JUMP_PROGRAM.pdf"
pdf2 = r"C:\Users\jagga\.gemini\antigravity\scratch\Routine Only.pdf"

extract_pdf(pdf1, "btr_output.txt")
extract_pdf(pdf2, "routine_only_output.txt")
