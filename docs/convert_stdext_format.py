import re
import sys
import os

def find_cpp_headers_and_sources(path):
    if os.path.isfile(path):
        return [path] if path.endswith((".cpp", ".hpp", ".h", ".cxx")) else []

    matched_files = []
    for root, _, filenames in os.walk(path):
        for filename in filenames:
            if filename.endswith((".cpp", ".hpp", ".h", ".cxx")):
                matched_files.append(os.path.join(root, filename))
    return matched_files

def convert_percent_format_to_fmt_style(format_string):
    return re.sub(r'%[dsufx]', '{}', format_string)

def replace_stdext_format_calls(content):
    pattern = re.compile(
        r'(g_logger\.(?:fine|debug|info|warning|error|fatal)\s*\(\s*)'
        r'stdext::format\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*((?:[^()]|\([^()]*\))+?)\s*\)(\s*\))'
    )

    def replace_match(match):
        logger_prefix = match.group(1)
        old_format_string = match.group(2)
        format_arguments = match.group(3)
        closing = match.group(4)

        new_format_string = convert_percent_format_to_fmt_style(old_format_string)
        return f'{logger_prefix}"{new_format_string}", {format_arguments}{closing}'

    return pattern.sub(replace_match, content)

def rewrite_files(file_paths):
    for file_path in file_paths:
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                original_content = file.read()
        except UnicodeDecodeError:
            with open(file_path, 'r', encoding='latin1') as file:
                original_content = file.read()

        updated_content = replace_stdext_format_calls(original_content)
        if original_content != updated_content:
            try:
                with open(file_path, 'w', encoding='utf-8') as file:
                    file.write(updated_content)
                print(f"[UPDATED] {file_path}")
            except Exception as e:
                print(f"[ERROR] Failed to write to {file_path}: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        base_path = sys.argv[1]
    else:
        base_path = os.path.abspath(os.path.join(os.getcwd(), ".."))
        print(f"[INFO] No path provided. Using parent directory: {base_path}")

    source_files = find_cpp_headers_and_sources(base_path)
    if not source_files:
        print("[WARN] No .cpp/.h files found.")
    else:
        rewrite_files(source_files)
