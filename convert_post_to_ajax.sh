#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   ./convert_post_to_ajax.sh <dir-ou-arquivo> [--dry-run] [--infer-put]

DRY_RUN=0
INFER_PUT=0
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
dry = int(sys.argv[2])      # 0/1
infer_put = int(sys.argv[3])# 0/1

with open(path, 'r', encoding='utf-8', errors='ignore') as f:
    src = f.read()

def find_matching_paren(code, start_pos):
    """Encontra o parênteses de fechamento correspondente"""
    pos = start_pos
    count = 1
    in_string = False
    string_char = None
    in_comment = False
    comment_type = None
    
    while pos < len(code) and count > 0:
        char = code[pos]
        
        # Comentário de linha
        if not in_string and not in_comment and char == '/' and pos + 1 < len(code) and code[pos + 1] == '/':
            in_comment = True
            comment_type = '//'
            pos += 2
            continue
            
        # Comentário de bloco
        if not in_string and not in_comment and char == '/' and pos + 1 < len(code) and code[pos + 1] == '*':
            in_comment = True
            comment_type = '/*'
            pos += 2
            continue
            
        # Fim de comentário
        if in_comment:
            if comment_type == '//' and char == '\n':
                in_comment = False
                comment_type = None
            elif comment_type == '/*' and char == '*' and pos + 1 < len(code) and code[pos + 1] == '/':
                in_comment = False
                comment_type = None
                pos += 2
                continue
            pos += 1
            continue
            
        # Strings
        if not in_comment:
            if not in_string and char in '"\'`':
                in_string = True
                string_char = char
            elif in_string and char == string_char:
                # Verificar escape
                escape_count = 0
                temp_pos = pos - 1
                while temp_pos >= 0 and code[temp_pos] == '\\':
                    escape_count += 1
                    temp_pos -= 1
                if escape_count % 2 == 0:  # Não está escapado
                    in_string = False
                    string_char = None
        
        # Contar parênteses apenas fora de strings e comentários
        if not in_string and not in_comment:
            if char == '(':
                count += 1
            elif char == ')':
                count -= 1
                
        pos += 1
    
    return pos - 1 if count == 0 else -1

def extract_post_args(args_str):
    """Extrai os argumentos separando por vírgula no nível superior"""
    if not args_str.strip():
        return '""', '{}'
    
    args = []
    current_arg = ""
    paren_count = 0
    brace_count = 0
    bracket_count = 0
    in_string = False
    string_char = None
    in_comment = False
    comment_type = None
    
    i = 0
    while i < len(args_str):
        char = args_str[i]
        
        # Comentários
        if not in_string and not in_comment and char == '/' and i + 1 < len(args_str):
            if args_str[i + 1] == '/':
                in_comment = True
                comment_type = '//'
                current_arg += char
                i += 1
                continue
            elif args_str[i + 1] == '*':
                in_comment = True
                comment_type = '/*'
                current_arg += char
                i += 1
                continue
        
        if in_comment:
            current_arg += char
            if comment_type == '//' and char == '\n':
                in_comment = False
                comment_type = None
            elif comment_type == '/*' and char == '*' and i + 1 < len(args_str) and args_str[i + 1] == '/':
                in_comment = False
                comment_type = None
                current_arg += '/'  # Adiciona o próximo '/'
                i += 1
            i += 1
            continue
        
        # Strings
        if not in_string and char in '"\'`':
            in_string = True
            string_char = char
            current_arg += char
        elif in_string and char == string_char:
            # Verificar escape
            escape_count = 0
            temp_pos = i - 1
            while temp_pos >= 0 and args_str[temp_pos] == '\\':
                escape_count += 1
                temp_pos -= 1
            if escape_count % 2 == 0:
                in_string = False
                string_char = None
            current_arg += char
        elif in_string:
            current_arg += char
        else:
            # Fora de strings e comentários
            if char == '(':
                paren_count += 1
                current_arg += char
            elif char == ')':
                paren_count -= 1
                current_arg += char
            elif char == '{':
                brace_count += 1
                current_arg += char
            elif char == '}':
                brace_count -= 1
                current_arg += char
            elif char == '[':
                bracket_count += 1
                current_arg += char
            elif char == ']':
                bracket_count -= 1
                current_arg += char
            elif char == ',' and paren_count == 0 and brace_count == 0 and bracket_count == 0:
                # Vírgula no nível superior - fim do argumento
                args.append(current_arg.strip())
                current_arg = ""
            else:
                current_arg += char
        
        i += 1
    
    # Último argumento
    if current_arg.strip():
        args.append(current_arg.strip())
    
    # Retorna no máximo 2 argumentos
    url = args[0] if len(args) > 0 else '""'
    data = args[1] if len(args) > 1 else '{}'
    
    return url, data

def skip_whitespace(code, pos):
    """Pula espaços em branco"""
    while pos < len(code) and code[pos].isspace():
        pos += 1
    return pos

def process_post_with_chain(code):
    """Processa $.post() e sua cadeia de .then()/.catch() em uma única passada"""
    result = []
    i = 0
    
    while i < len(code):
        # Procurar por $.post(
        if code.startswith('$.post(', i):
            post_start = i
            
            # Encontrar o final do $.post()
            paren_start = i + 7  # posição após '$.post('
            paren_end = find_matching_paren(code, paren_start)
            
            if paren_end == -1:
                # Parênteses não fechado, copiar como está
                result.append(code[i])
                i += 1
                continue
            
            # Extrair argumentos do $.post()
            args_str = code[paren_start:paren_end]
            url, data = extract_post_args(args_str)
            
            # Calcular indentação
            line_start = code.rfind('\n', 0, post_start) + 1
            indent = ''
            for j in range(line_start, len(code)):
                if code[j] in ' \t':
                    indent += code[j]
                else:
                    break
            
            # Determinar método
            method = "POST"
            if infer_put:
                # Verificar se URL termina com /put
                url_clean = url.strip().strip('"\'`')
                if url_clean.endswith('/put') or '/put' in url_clean:
                    method = "PUT"
            
            # Gerar $.ajax()
            ajax_code = (
                "$.ajax({\n" +
                indent + "  url: " + url + ",\n" +
                indent + "  method: \"" + method + "\",\n" +
                indent + "  contentType: \"application/json; charset=UTF-8\",\n" +
                indent + "  dataType: \"json\",\n" +
                indent + "  data: JSON.stringify(" + data + ")\n" +
                indent + "})"
            )
            
            # Avançar para depois do $.post()
            current_pos = paren_end + 1
            
            # Processar cadeia de .then() e .catch() que vem após o $.post()
            chain_parts = []
            
            while current_pos < len(code):
                # Pular espaços
                current_pos = skip_whitespace(code, current_pos)
                if current_pos >= len(code):
                    break
                
                # Verificar se há .then(
                if code.startswith('.then(', current_pos):
                    then_paren_start = current_pos + 6
                    then_paren_end = find_matching_paren(code, then_paren_start)
                    
                    if then_paren_end == -1:
                        break
                    
                    # Extrair argumentos do .then()
                    then_args_str = code[then_paren_start:then_paren_end]
                    success_arg, error_arg = extract_post_args(then_args_str)
                    
                    current_pos = then_paren_end + 1
                    
                    # Verificar se há dois argumentos
                    if error_arg and error_arg != '{}' and error_arg.strip():
                        # .then(success, error) -> .done(success).fail(error)
                        chain_parts.append('.done(' + success_arg + ').fail(' + error_arg + ')')
                        
                        # Verificar se há .catch() logo após e pular
                        next_pos = skip_whitespace(code, current_pos)
                        if code.startswith('.catch(', next_pos):
                            catch_paren_start = next_pos + 7
                            catch_paren_end = find_matching_paren(code, catch_paren_start)
                            if catch_paren_end != -1:
                                current_pos = catch_paren_end + 1  # Pula o .catch()
                    else:
                        # .then(success) -> .done(success)
                        chain_parts.append('.done(' + success_arg + ')')
                        
                        # Verificar se há .catch() logo após
                        next_pos = skip_whitespace(code, current_pos)
                        if code.startswith('.catch(', next_pos):
                            catch_paren_start = next_pos + 7
                            catch_paren_end = find_matching_paren(code, catch_paren_start)
                            if catch_paren_end != -1:
                                catch_args = code[catch_paren_start:catch_paren_end]
                                chain_parts.append('.fail(' + catch_args + ')')
                                current_pos = catch_paren_end + 1
                    
                    continue
                
                # Verificar se há .catch( (sozinho)
                elif code.startswith('.catch(', current_pos):
                    catch_paren_start = current_pos + 7
                    catch_paren_end = find_matching_paren(code, catch_paren_start)
                    
                    if catch_paren_end == -1:
                        break
                    
                    catch_args = code[catch_paren_start:catch_paren_end]
                    chain_parts.append('.fail(' + catch_args + ')')
                    current_pos = catch_paren_end + 1
                    continue
                
                else:
                    # Não é mais .then() nem .catch(), para aqui
                    break
            
            # Montar resultado final
            full_result = ajax_code + ''.join(chain_parts)
            result.append(full_result)
            i = current_pos
            
        else:
            result.append(code[i])
            i += 1
    
    return ''.join(result)

# Processar o código em uma única passada
new_src = process_post_with_chain(src)

changed = (new_src != src)

if changed:
    if dry:
        print(f"[dry-run] {path} -> alterado")
    else:
        bak = path + ".bak"
        with open(bak, 'w', encoding='utf-8', errors='ignore') as f:
            f.write(src)
        with open(path, 'w', encoding='utf-8', errors='ignore') as f:
            f.write(new_src)
        print(f"[ok] {path} -> alterado | backup: {bak}")
else:
    if dry:
        print(f"[dry-run] {path} -> sem alterações")

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