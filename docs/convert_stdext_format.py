import re
import sys
import os

def find_cpp_files(path):
    if os.path.isfile(path):
        return [path] if path.endswith((".cpp", ".hpp", ".h", ".cxx")) else []
    files = []
    for root, _, filenames in os.walk(path):
        for name in filenames:
            if name.endswith((".cpp", ".hpp", ".h", ".cxx")):
                files.append(os.path.join(root, name))
    return files

def convert_format_string(fmt_str):
    return re.sub(r'%[dsufx]', '{}', fmt_str)

def convert_content(content):
    # Apenas chamadas dentro de g_logger.XYZ(...)
    pattern = re.compile(
        r'(g_logger\.(?:fine|debug|info|warning|error|fatal|traceDebug|traceInfo|traceWarning|traceError)\s*\(\s*)'
        r'stdext::format\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*((?:[^()]|\([^()]*\))+?)\s*\)(\s*\))'
    )

    def replacer(match):
        prefix = match.group(1)  # ex: g_logger.warning(
        fmt_str = match.group(2)  # ex: "foo %s"
        args = match.group(3)     # ex: var1, var2
        suffix = match.group(4)   # fecha o parênteses
        new_fmt = convert_format_string(fmt_str)
        return f'{prefix}"{new_fmt}", {args}{suffix}'

    return pattern.sub(replacer, content)

def process_files(paths):
    for path in paths:
        try:
            with open(path, 'r', encoding='utf-8') as f:
                original = f.read()
        except UnicodeDecodeError:
            with open(path, 'r', encoding='latin1') as f:
                original = f.read()

        converted = convert_content(original)
        if original != converted:
            try:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(converted)
                print(f"[UPDATED] {path}")
            except Exception as e:
                print(f"[ERROR] Falha ao escrever {path}: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        target_path = sys.argv[1]
    else:
        # Diretório pai do diretório atual
        target_path = os.path.abspath(os.path.join(os.getcwd(), ".."))
        print(f"[INFO] Nenhum caminho especificado. Usando diretório pai: {target_path}")

    files = find_cpp_files(target_path)
    if not files:
        print("[WARN] Nenhum arquivo .cpp/.h encontrado.")
    else:
        process_files(files)
