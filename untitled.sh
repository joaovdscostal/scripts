#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   ./convert_post_to_ajax.sh <caminho> [--dry-run] [--infer-put]
#
# <caminho> pode ser um diretório ou arquivo(s). O script procura por extensões comuns de front-end.
# --dry-run   : mostra quais arquivos seriam alterados sem gravar
# --infer-put : se a URL for string e terminar com "/put", usa method: "PUT" em vez de "POST"

DRY_RUN=0
INFER_PUT=0
ROOT=""
ARGS=()

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --infer-put) INFER_PUT=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done

if [ ${#ARGS[@]} -eq 0 ]; then
  echo "Uso: $0 <dir-ou-arquivo> [--dry-run] [--infer-put]"
  exit 1
fi

process_file() {
  local file="$1"
  local dry="$2"
  local infer="$3"

  python3 - "$file" "$dry" "$infer" <<'PYCODE'
import sys, os

path = sys.argv[1]
dry = int(sys.argv[2])  # 0/1
infer_put = int(sys.argv[3])  # 0/1

with open(path, 'r', encoding='utf-8', errors='ignore') as f:
    src = f.read()

# Estados de parser simples p/ evitar trocar dentro de strings/comentários
def find_calls(code):
    i = 0
    n = len(code)
    results = []
    in_s = in_d = in_bq = False  # ' " `
    in_sl_comment = False
    in_ml_comment = False
    escape = False

    def match_at(pos, s):
        return code.startswith(s, pos)

    while i < n:
        c = code[i]

        if in_sl_comment:
            if c == '\n':
                in_sl_comment = False
            i += 1
            continue

        if in_ml_comment:
            if c == '*' and i+1 < n and code[i+1] == '/':
                in_ml_comment = False
                i += 2
            else:
                i += 1
            continue

        if in_s:
            if not escape and c == '\\':
                escape = True
            elif escape:
                escape = False
            elif c == "'":
                in_s = False
            i += 1
            continue

        if in_d:
            if not escape and c == '\\':
                escape = True
            elif escape:
                escape = False
            elif c == '"':
                in_d = False
            i += 1
            continue

        if in_bq:
            if not escape and c == '\\':
                escape = True
            elif escape:
                escape = False
            elif c == '`':
                in_bq = False
            i += 1
            continue

        # fora de strings/comentários
        if c == '/':
            if i+1 < n and code[i+1] == '/':
                in_sl_comment = True
                i += 2
                continue
            if i+1 < n and code[i+1] == '*':
                in_ml_comment = True
                i += 2
                continue

        if c == "'":
            in_s = True; i += 1; continue
        if c == '"':
            in_d = True; i += 1; continue
        if c == '`':
            in_bq = True; i += 1; continue

        # procurar $.post( ou jQuery.post(
        if match_at(i, '$.post(') or match_at(i, 'jQuery.post('):
            call_start = i
            # p após '('
            p = i + (len('$.post(') if match_at(i,'$.post(') else len('jQuery.post('))
            paren = 1
            in_s2=in_d2=in_bq2=False
            esc2=False
            # vamos até fechar a chamada ) correspondente
            while p < n and paren > 0:
                ch = code[p]
                if in_s2:
                    if not esc2 and ch == '\\':
                        esc2 = True
                    elif esc2:
                        esc2 = False
                    elif ch == "'":
                        in_s2 = False
                    p += 1; continue
                if in_d2:
                    if not esc2 and ch == '\\':
                        esc2 = True
                    elif esc2:
                        esc2 = False
                    elif ch == '"':
                        in_d2 = False
                    p += 1; continue
                if in_bq2:
                    if not esc2 and ch == '\\':
                        esc2 = True
                    elif esc2:
                        esc2 = False
                    elif ch == '`':
                        in_bq2 = False
                    p += 1; continue

                if ch == "'": in_s2=True; p+=1; continue
                if ch == '"': in_d2=True; p+=1; continue
                if ch == '`': in_bq2=True; p+=1; continue

                if ch == '(':
                    paren += 1
                elif ch == ')':
                    paren -= 1
                p += 1

            if paren != 0:
                # não conseguiu fechar, ignora
                i += 1
                continue

            call_end = p  # posição logo após ')'
            args_str = code[i:call_end]  # $.post(...)

            # extrair argumentos dentro dos parênteses
            inner = args_str[args_str.find('(')+1:-1].strip()

            # split de argumentos top-level por vírgula
            def split_top_level(s):
                parts=[]
                buf=[]
                d1=d2=db=0 # aspas
                esc=False
                par=br=brc=0
                for idx,ch in enumerate(s):
                    if d1:
                        buf.append(ch)
                        if not esc and ch == '\\':
                            esc=True
                        elif esc:
                            esc=False
                        elif ch=="'":
                            d1=0
                        continue
                    if d2:
                        buf.append(ch)
                        if not esc and ch == '\\':
                            esc=True
                        elif esc:
                            esc=False
                        elif ch=='"':
                            d2=0
                        continue
                    if db:
                        buf.append(ch)
                        if not esc and ch == '\\':
                            esc=True
                        elif esc:
                            esc=False
                        elif ch=='`':
                            db=0
                        continue
                    if ch=="'": d1=1; buf.append(ch); continue
                    if ch=='"': d2=1; buf.append(ch); continue
                    if ch=='`': db=1; buf.append(ch); continue
                    if ch=='(' : par+=1; buf.append(ch); continue
                    if ch==')' : par-=1; buf.append(ch); continue
                    if ch=='[' : br+=1; buf.append(ch); continue
                    if ch==']' : br-=1; buf.append(ch); continue
                    if ch=='{' : brc+=1; buf.append(ch); continue
                    if ch=='}' : brc-=1; buf.append(ch); continue
                    if ch==',' and par==0 and br==0 and brc==0:
                        parts.append(''.join(buf).strip()); buf=[]
                    else:
                        buf.append(ch)
                if buf:
                    parts.append(''.join(buf).strip())
                return parts

            args = split_top_level(inner)
            if len(args) < 1:
                i += 1
                continue

            url_expr = args[0].strip()
            data_expr = args[1].strip() if len(args) >= 2 else None

            # Heurística: PUT se a URL for literal e terminar com /put (opcional)
            method = "POST"
            if infer_put and url_expr and url_expr[0] in "'\"`" and url_expr[-1] == url_expr[0]:
                url_lit = url_expr[1:-1]
                if url_lit.lower().rstrip().endswith('/put'):
                    method = "PUT"

            # Indentação do começo da linha
            line_start = code.rfind('\n', 0, call_start) + 1
            indent = ''
            k = line_start
            while k < len(code) and code[k] in ' \t':
                indent += code[k]; k += 1

            # Montar $.ajax(...)
            # Se não houver data, usa {} para manter estrutura válida
            data_inside = data_expr if data_expr else "{}"

            new_call_lines = [
                f'$.ajax({{',
                f'{indent}  url: {url_expr},',
                f'{indent}  method: "{method}",',
                f'{indent}  contentType: "application/json; charset=UTF-8",',
                f'{indent}  dataType: "json",',
                f'{indent}  data: JSON.stringify({data_inside})',
                f'{indent}}})'
            ]
            new_call = '\n'.join([indent + new_call_lines[0]] + new_call_lines[1:])

            results.append((call_start, call_end, new_call))
            i = call_end
            continue

        i += 1

    return results

calls = find_calls(src)
if not calls:
    sys.exit(0)

# aplicar substituições do fim para o começo
calls.sort(key=lambda x: x[0], reverse=True)
new_src = src
for a, b, rep in calls:
    new_src = new_src[:a] + rep + new_src[b:]

if new_src != src:
    if dry:
        print(f"[dry-run] {path} -> {len(calls)} ocorrência(s) convertida(s)")
    else:
        # backup
        bak = path + ".bak"
        with open(bak, 'w', encoding='utf-8', errors='ignore') as f:
            f.write(src)
        with open(path, 'w', encoding='utf-8', errors='ignore') as f:
            f.write(new_src)
        print(f"[ok] {path} -> {len(calls)} ocorrência(s) convertida(s) (backup em {bak})")
PYCODE
}

TARGETS=()
for p in "${ARGS[@]}"; do
  if [ -d "$p" ]; then
    while IFS= read -r -d '' f; do
      TARGETS+=("$f")
    done < <(find "$p" -type f \( -name "*.js" -o -name "*.jsp" -o -name "*.jspf" -o -name "*.tag" -o -name "*.html" -o -name "*.htm" \) -print0)
  elif [ -f "$p" ]; then
    TARGETS+=("$p")
  else
    echo "Ignorando: $p (não encontrado)"
  fi
done

if [ ${#TARGETS[@]} -eq 0 ]; then
  echo "Nada para processar."
  exit 0
fi

for f in "${TARGETS[@]}"; do
  process_file "$f" "$DRY_RUN" "$INFER_PUT"
done
