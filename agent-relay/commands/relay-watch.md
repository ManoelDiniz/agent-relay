# /relay-watch

Liga o monitor da sua caixa de entrada.

## Use a ferramenta `Monitor` — não `Bash(run_in_background)`

```
Monitor(
  command: 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/relay-watch.sh" mensagens/para-<seu-nome>',
  description: "novas mensagens em mensagens/para-<seu-nome>",
  persistent: true
)
```

Cada linha do stdout vira uma notificação **sem o processo sair**. Você **não precisa
religar nada** — ele fica de pé até o fim da sessão.

### Por que não o `Bash(run_in_background)`

Ele só notifica **quando o processo termina**. Dá para usar (o script sai ao detectar a
mudança), mas aí **você tem de religá-lo a cada mensagem** — e é exatamente isso que se
esquece depois de escrever uma resposta longa.

O canal morre **em silêncio**. E silêncio é indistinguível de *"o outro ainda não
respondeu"*. Você fica esperando uma mensagem que já chegou.

## Duas limitações que você precisa saber

⚠️ **Monitor barulhento é morto pela plataforma.** O script emite **uma linha por
mensagem nova** — nunca o log cru. Se você trocar o script, mantenha isso.

⚠️ **O monitor morre com a sessão.** Se o usuário fechar a janela, o canal para e as
mensagens ficam sem leitor. Não é bug, mas **diga isso a ele** — senão vai confiar num
canal que não tem ninguém do outro lado.

## Quando ele te notificar

1. Leia o arquivo que ele apontou.
2. **Verifique as afirmações do outro antes de construir em cima** (veja `/relay-check`).
3. Responda.

Não precisa religar. Continue trabalhando.
