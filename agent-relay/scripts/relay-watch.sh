#!/usr/bin/env bash
#
# Vigia a caixa de entrada de um agente e emite UMA LINHA por mensagem nova.
#
# Feito para a ferramenta Monitor (não para Bash com run_in_background):
#   Monitor(
#     command: 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/relay-watch.sh" mensagens/para-back',
#     description: 'novas mensagens em mensagens/para-back',
#     persistent: true
#   )
#
# Cada linha do stdout vira uma notificação, e o processo NÃO precisa sair — então não
# existe o "esqueci de religar o monitor". Uma linha por mensagem, nunca log cru:
# monitor barulhento é morto pela plataforma.
#
# uso:  relay-watch.sh <pasta-da-caixa> [segundos-entre-checagens]
#
set -u

CAIXA="${1:?uso: relay-watch.sh <pasta-da-caixa> [intervalo]}"
INTERVALO="${2:-5}"

mkdir -p "$CAIXA"

# ---------------------------------------------------------------------------
# Portabilidade: NÃO use `find -printf` nem `stat -c` direto.
#
# `-printf` é GNU findutils e `stat -c` é GNU coreutils. O macOS traz as versões
# BSD, que não têm nenhum dos dois. Uma versão anterior deste script usava
# `find -printf` com `2>/dev/null` — e no macOS ela devolvia string VAZIA para
# sempre. O monitor rodava feliz, nunca emitia nada, e o agente concluía "o canal
# está aberto, o outro não respondeu".
#
# Um monitor cego é PIOR que monitor nenhum: ele dá confiança.
# ---------------------------------------------------------------------------
if stat -c '%Y' . >/dev/null 2>&1; then
  ler_mtime() { stat -c '%Y' "$1"; }      # GNU (Linux, Git Bash)
else
  ler_mtime() { stat -f '%m' "$1"; }      # BSD (macOS)
fi

# Lista crua: TUDO, inclusive o arquivo-sonda. É o que o autoteste precisa enxergar.
#
# O `sort` vem DEPOIS de montar a linha, não antes: o `comm` compara linhas inteiras e
# exige as duas entradas ordenadas por linha. Ordenar só os nomes e depois prefixar o
# mtime produz uma lista fora de ordem — o `comm` reclama e reemite mensagens antigas
# como se fossem novas. LC_ALL=C fixa a ordenação, que varia por locale.
#
# -maxdepth 1 NÃO é otimização: é correção.
#
# O protocolo manda mover a mensagem tratada para `<caixa>/lidas/`. Sem o -maxdepth,
# o `find` desce na subpasta e o arquivo REAPARECE com um caminho novo — o `comm` o vê
# como linha inédita e emite "MENSAGEM NOVA -> .../lidas/back-009.md".
#
# Ou seja: arquivar uma mensagem te acordava para a mensagem que você ACABOU de tratar.
# Um alarme que mente treina o agente a ignorar alarmes — e aí o alarme que importa
# passa batido também.
listar() {
  find "$CAIXA" -maxdepth 1 -type f | while read -r f; do
    echo "$(ler_mtime "$f") $f"
  done | LC_ALL=C sort
}

# O que o monitor observa: mensagens de verdade, sem a sonda nem outros ocultos.
snapshot() {
  listar | grep -v '/\.'
}

# ---------------------------------------------------------------------------
# Autoteste: PROVE que enxerga antes de afirmar que vigia.
#
# Cria um arquivo-sonda e exige vê-lo. Se `find`/`stat` forem incompatíveis (ou
# faltar permissão), TODOS os modos de falha terminariam em silêncio — e silêncio é
# indistinguível de "não chegou mensagem". Gritar aqui é a única defesa.
#
# ATENÇÃO: o autoteste usa `listar`, não `snapshot`. Uma versão anterior testava com
# `snapshot`, que filtra a sonda — então numa caixa VAZIA o resultado era vazio e o
# script acusava cegueira estando são. Um autoteste que dá falso positivo é tão ruim
# quanto não ter autoteste: ensina a ignorar o alarme.
# ---------------------------------------------------------------------------
probe="$CAIXA/.relay-probe"
: > "$probe"
if ! listar | grep -q '\.relay-probe$'; then
  echo "ERRO: relay-watch nao consegue LER a caixa '$CAIXA'. O canal NAO esta vigiado."
  echo "      (find/stat incompativeis, ou sem permissao). Corrija antes de confiar no canal."
  rm -f "$probe"
  exit 1
fi
rm -f "$probe"

anterior="$(snapshot)"

while true; do
  atual="$(snapshot)"

  if [ "$atual" != "$anterior" ]; then
    # mtime + caminho: pega arquivo NOVO e arquivo EDITADO (alguém corrigindo a
    # própria mensagem) — um `ls` simples perderia o segundo caso.
    comm -13 <(echo "$anterior") <(echo "$atual") | while read -r _ caminho; do
      [ -n "$caminho" ] && echo "MENSAGEM NOVA -> $caminho"
    done
    anterior="$atual"
  fi

  sleep "$INTERVALO"
done
