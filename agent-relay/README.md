# agent-relay

**Vários agentes Claude Code, um repositório, sem se atropelarem.**

Quando duas sessões do Claude Code trabalham no mesmo projeto ao mesmo tempo, o problema
não é a inteligência de cada uma. É que **elas não se veem**:

- uma reescreve o arquivo que a outra está editando;
- uma muda o contrato enquanto a outra codifica contra o antigo;
- uma afirma *"isso já funciona"* e a outra constrói em cima da afirmação;
- e **você** vira o cabo de rede entre as duas, repetindo tudo dos dois lados.

Este plugin dá a elas um **canal de arquivos**, um **monitor** que as notifica quando
chega mensagem, e um **protocolo** de coordenação.

Ele é **genérico**: não sabe nada do seu domínio. Tudo o que é específico do seu projeto
(quem são os agentes, o território de cada um, os contratos, os buracos conhecidos) vai
para o `mensagens/PROTOCOLO.md` **daquele repositório** — nunca para o plugin.

---

## Instalar

```
/plugin marketplace add ManoelDiniz/agent-relay
/plugin install agent-relay@agent-relay
```

## Usar

Em **cada** sessão (uma por agente):

```
/relay-init back front
```

O `init` **pergunta** quem são os agentes e qual o território de cada um — ele não
adivinha. Podem ser dois, podem ser quatro (`dados`, `infra`, `mobile`, `docs`).

Depois, **dê a instrução a um só deles.** Quem recebe avisa o outro, e eles se coordenam.

| Comando | O que faz |
|---|---|
| `/relay-init <você> <outros...>` | abre o canal e declara o território |
| `/relay-check` | lê a caixa de entrada e responde |
| `/relay-send <mensagem>` | escreve para outro agente |
| `/relay-watch` | liga o monitor |

A skill também carrega **sozinha** quando o Claude percebe outro agente no repositório —
inclusive quando vê arquivos mudando sem ter sido ele.

---

## O que o protocolo evita

| Erro real | Regra |
|---|---|
| Dois agentes reescreveram os mesmos arquivos; um apagou o trabalho do outro | **Território sem interseção** — todo caminho tem um dono |
| Um passou a exigir um campo novo e derrubou o canal do outro | **Migração em duas fases** — anuncia → o outro tolera → só então exige |
| Os dois renomearam o contrato ao mesmo tempo, cada um adotando o do outro | **Quem é dono da camada nomeia** — nunca renomeie em paralelo |
| *"A interface não alcança esse bug"* — alcançava | **Evidência do sistema rodando**, não do código lido |
| *"Verifiquei, funciona"* — o teste rodara fora do servidor | idem — e **duvide do instrumento** |
| Um pediu uma mudança que faria a tela mentir; o outro ia obedecer | **Recusar é parte do trabalho** |
| Os dois decidiriam sozinhos uma regra de negócio | **Decisão de negócio escala pro dono** |
| Os dois esperando um pelo outro, para sempre | **`pronto` = nenhum pedido seu em aberto**; bloqueio circular = deadlock |
| A ponte de compatibilidade virou herança permanente | **Compatibilidade é ponte, não destino** — abra o item de limpeza junto |

---

## O monitor: a armadilha que quase nos pegou

Use a ferramenta **`Monitor`**, não `Bash(run_in_background)`.

| | notifica quando | precisa religar? |
|---|---|---|
| `Bash(run_in_background)` | o processo **sai** | **sim**, a cada mensagem |
| **`Monitor`** | **cada linha do stdout**, processo segue vivo | **não** |

Com o background bash, o monitor precisa sair para te notificar — e aí **você tem de
religá-lo**. É exatamente isso que se esquece depois de escrever uma resposta longa. O
canal morre **em silêncio**, e silêncio é indistinguível de *"o outro ainda não
respondeu"*: você fica esperando uma mensagem que já chegou.

Duas limitações reais, que **precisam estar ditas**:

- ⚠️ **Monitor barulhento é morto pela plataforma.** Emita **uma linha por mensagem
  nova**, nunca o log cru.
- ⚠️ **O monitor morre com a sessão.** Fechou a janela, o canal parou. Não é bug — mas
  quem não souber vai confiar num canal sem ninguém do outro lado.

---

## Nota

Este plugin nasceu de dois agentes que passaram uma tarde inteira se atropelando num
projeto real, e depois foram obrigados a explicar um ao outro **por que** cada erro
aconteceu. Cada regra aqui é a cicatriz de um erro concreto.

O que **não** está aqui, de propósito: nada sobre o domínio daquele projeto. Se uma
regra só faz sentido sabendo o que o sistema faz, ela **não é do plugin** — é do
`PROTOCOLO.md` do repositório.
