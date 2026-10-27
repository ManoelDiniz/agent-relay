# /relay-check

Lê as mensagens que chegaram para você e responde.

## O que fazer

1. Liste `mensagens/para-<seu-nome>/`. **Tudo o que está lá (fora de `lidas/`) é
   pendência** — o que já foi tratado foi movido, então não há o que lembrar.

2. Para cada mensagem, aja conforme o `Status`:
   - `bloqueante` — largue o que está fazendo e resolva.
   - `pedido` — encaixe no seu trabalho.
   - `aviso` — leia e arquive.
   - `pronto` — **confira** e feche.

3. 🔴 **Antes de construir em cima de qualquer afirmação dele, verifique.**

   Não é desconfiança, é a regra que mais salvou este protocolo. Já aconteceu, dos
   dois lados, de um agente afirmar com toda a convicção algo que não era verdade —
   porque leu o código por cima, ou porque testou fora do servidor.

   Se ele diz *"o endpoint X está no ar"*, **bata no endpoint**.
   Se ele diz *"a tela já trata isso"*, **abra o arquivo**.
   Leva um minuto, e a alternativa é construir sobre areia.

4. Responda em `mensagens/para-<outro>/NNN-<assunto>.md`, com o próximo número:
   - o que você **testou** (cole a saída real, não descreva);
   - o que você mudou e o que isso **quebra** do lado dele;
   - onde você **discorda** — discordar cedo é barato.

   Se ele te corrigiu: **assuma e registre**. O objetivo não é ter razão.

5. **Mova a mensagem tratada para `mensagens/para-<seu-nome>/lidas/`.** É isso que faz
   a caixa ser a lista de pendências — e o que te salva na próxima sessão, quando você
   não vai lembrar de nada.

6. **O monitor (`Monitor`, persistente) não precisa ser religado.** Se você usou
   `Bash(run_in_background)`, aí sim precisa — e é o que se esquece:
   ```
   Monitor(command: 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/relay-watch.sh" mensagens/para-<seu-nome>',
           description: "novas mensagens", persistent: true)
   ```

6. Conte ao usuário **o que importa** da troca — não cole a mensagem inteira. Ele
   quer saber o que mudou e o que isso significa, não ler a correspondência.
