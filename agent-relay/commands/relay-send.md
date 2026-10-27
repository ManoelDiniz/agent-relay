# /relay-send

Escreve uma mensagem para o outro agente.

## Uso

```
/relay-send <o que você quer dizer>
```

## O que fazer

1. Descubra o próximo número em `mensagens/para-<outro>/` e crie
   `<seu-nome>-NNN-<assunto>.md` — **o arquivo começa com o SEU nome**, e cada
   agente incrementa o próprio contador. Sem isso, dois agentes criam o `007-` ao
   mesmo tempo e um apaga o outro..

2. Comece sempre pelo cabeçalho:

   ```markdown
   # <seu-nome>-007 — <uma frase que diz o que é>

   **De:** back · **Para:** front · **Status:** bloqueante
   **Responde:** front-004     (ou —)
   ```

   `Status`: `bloqueante` · `pedido` · `aviso` · `pronto`.

3. Escreva para quem **não viu nada do que você fez**. Ele não acompanhou o seu
   raciocínio, não conhece os apelidos que você inventou, e não vai perguntar.

## O que uma boa mensagem tem

**Diga o que você TESTOU, não o que deveria funcionar.** Cole a saída real:

```
POST /produtos {}   -> 400 (não 403)   => o @Roles liberou o atendente  ✔
```

Um `400` em vez de `403` prova a permissão. "Implementei o endpoint" não prova nada.

**Se você vai quebrar o lado dele, o assunto é isso — e vem primeiro.** Marque no
título (`🔴 BREAKING`), diga exatamente o que quebra, e **dê o diff pronto**. Melhor
ainda: anuncie **antes** de subir, deixe ele pré-cablar a tolerância, e só então
suba.

**Se for `bloqueante`, diga o que você faz enquanto espera.** Ficar parado é
desperdício. Construir em cima de um palpite é pior.

**Se você discorda, discorde agora.** É muito mais barato do que descobrir com os
dois lados prontos.

## O que NÃO fazer

- ❌ **Não renomeie o contrato dele achando que ele vai acompanhar.** Quem é dono da
  camada nomeia. Se você discorda do nome, **discuta** — não mude do seu lado.
- ❌ Não descreva o que "deve estar funcionando". Ou você rodou, ou não sabe.
- ❌ Não peça o que você mesmo pode verificar. Abra o código dele antes de perguntar.
