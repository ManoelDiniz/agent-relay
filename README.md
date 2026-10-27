# agent-relay

> Plugin para Claude Code que coordena vários agentes trabalhando no mesmo repositório ao mesmo tempo, por um canal de arquivos.

![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-D97757?logo=anthropic&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-script-4EAA25?logo=gnubash&logoColor=white)
![Markdown](https://img.shields.io/badge/Markdown-skill%20%2B%20commands-000000?logo=markdown&logoColor=white)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)

## O que faz

Quando duas ou mais sessões do Claude Code mexem no mesmo projeto, elas não se veem: uma
reescreve o arquivo que a outra está editando, muda um contrato sem avisar ou afirma que algo
"já funciona" sem ter testado. O `agent-relay` dá a elas:

- **Um canal de arquivos** — cada agente tem uma caixa de entrada em `mensagens/para-<nome>/`,
  mensagens numeradas por remetente e com cabeçalho obrigatório (status `bloqueante`, `pedido`,
  `aviso` ou `pronto`); mensagens tratadas vão para `lidas/`.
- **Um monitor** (`scripts/relay-watch.sh`) feito para a ferramenta `Monitor`: emite uma linha
  por mensagem nova, sem precisar ser religado, com autoteste que acusa quando não consegue ler
  a caixa e compatível com GNU e BSD (Linux, Git Bash, macOS).
- **Um protocolo de coordenação** (skill `agent-relay`): território declarado sem interseção,
  quem é dono da camada nomeia o contrato, migração em duas fases para mudanças que quebram o
  outro lado, afirmação sempre acompanhada de evidência do sistema rodando, decisão de negócio
  escalada para o dono e condição de encerramento sem deadlock.

A skill carrega sozinha quando o Claude percebe outro agente no repositório. O plugin é
genérico: o que for específico do seu projeto vai para o `mensagens/PROTOCOLO.md` dele.

### Comandos

| Comando | O que faz |
|---|---|
| `/relay-init <você> <outros...>` | abre o canal e declara o território de cada agente |
| `/relay-check` | lê a caixa de entrada e responde |
| `/relay-send <mensagem>` | escreve para outro agente |
| `/relay-watch` | liga o monitor da caixa de entrada |

## Arquitetura

```
.claude-plugin/marketplace.json     marketplace (permite /plugin marketplace add deste repo)
agent-relay/
  .claude-plugin/plugin.json        manifesto do plugin
  skills/agent-relay/SKILL.md       protocolo: mecânica (M1–M4) e coordenação (C1–C9)
  commands/relay-*.md               os quatro comandos de barra
  scripts/relay-watch.sh            monitor da caixa de entrada (uma linha por mensagem nova)
  README.md                         documentação detalhada do plugin
```

No repositório onde os agentes trabalham, o canal fica assim:

```
mensagens/
  PROTOCOLO.md                 agentes, território e regras locais daquele projeto
  para-<nome>/                 caixa de entrada: o que falta tratar
    <remetente>-003-slug.md
    lidas/                     mensagens já tratadas
```

## Como rodar

No Claude Code:

```
/plugin marketplace add ManoelDiniz/agent-relay
/plugin install agent-relay@agent-relay
```

Depois, em **cada** sessão (uma por agente):

```
/relay-init back front
/relay-watch
```

Dê a tarefa a um só dos agentes — quem recebe avisa o outro e eles se coordenam pelo canal.
O monitor usa `bash`, `find`, `stat`, `sort` e `comm`; no Windows, rode pelo Git Bash.

Mais detalhes em [`agent-relay/README.md`](agent-relay/README.md).

## Tecnologias

- Plugin do Claude Code (marketplace, skill e slash commands em Markdown)
- Bash (monitor portável GNU/BSD)

## Licença

MIT
