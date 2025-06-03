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

def convert_percent_format_to_fmt_style(fmt_str):
    # Converte %d, %u, %s, %f, %x, %lu etc. para {}
    return re.sub(r'%(\d*\.*\d*[dsufx]|l[ud])', '{}', fmt_str)

def replace_logger_stdext_format(content):
    pattern = re.compile(
        r'(g_logger\.(?:fine|debug|info|warning|error|fatal)\s*\(\s*)'
        r'stdext::format\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*((?:[^()]|\([^()]*\))+?)\s*\)(\s*\))'
    )
    def replacer(match):
        prefix, fmt_str, args, suffix = match.groups()
        fmt_str = convert_percent_format_to_fmt_style(fmt_str)
        return f'{prefix}"{fmt_str}", {args}{suffix}'
    return pattern.sub(replacer, content)

def replace_general_stdext_format(content):
    # Para usos como: name = stdext::format(...);
    pattern = re.compile(
        r'stdext::format\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*((?:[^()]|\([^()]*\))+?)\s*\)'
    )
    def replacer(match):
        fmt_str, args = match.groups()
        fmt_str = convert_percent_format_to_fmt_style(fmt_str)
        return f'fmt::format("{fmt_str}", {args})'
    return pattern.sub(replacer, content)

def replace_exception_format(content):
    pattern = re.compile(
        r'throw\s+Exception\s*\(\s*"((?:[^"\\]|\\.)*?)"\s*,\s*((?:[^()]|\([^()]*\))+?)\s*\)'
    )
    def replacer(match):
        fmt_str, args = match.groups()
        fmt_str = convert_percent_format_to_fmt_style(fmt_str)
        return f'throw Exception("{fmt_str}", {args})'
    return pattern.sub(replacer, content)

def rewrite_files(file_paths):
    for file_path in file_paths:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                original = f.read()
        except UnicodeDecodeError:
            with open(file_path, 'r', encoding='latin1') as f:
                original = f.read()

        content = replace_logger_stdext_format(original)
        content = replace_general_stdext_format(content)
        content = replace_exception_format(content)  # <--- Aqui

        if content != original:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"[UPDATED] {file_path}")
            except Exception as e:
                print(f"[ERROR] Failed to write {file_path}: {e}")

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
