---
name: agent-relay
description: Coordena dois ou mais agentes Claude Code que trabalham no MESMO repositório ao mesmo tempo, por um canal de arquivos. Use quando o usuário disser que há outro agente/Claude/sessão mexendo no projeto, quando pedir para "falar com o outro agente", "avisar o outro", "orquestrar", "dividir o trabalho", ou quando já existir um canal (mensagens/, relay/, dialogo_*). Use também ao PERCEBER outro agente editando os mesmos arquivos (arquivos mudando sozinhos, "modified by the user or a linter" em código que você não escreveu). Traz a mecânica do canal, o monitor que te acorda, a divisão de território, a migração em duas fases que evita quebrar o outro lado, e a condição de encerramento sem deadlock. Triggers: outro agente, outro claude, multi-agente, orquestrar, coordenar, canal, relay, handoff, dois agentes, sessões paralelas.
---

# agent-relay — vários agentes, um repositório

Quando dois agentes Claude Code trabalham no mesmo repo ao mesmo tempo, o problema não
é a inteligência de cada um. É que **eles não se veem**:

- um reescreve o arquivo que o outro está editando;
- um muda o contrato enquanto o outro codifica contra o antigo;
- um afirma *"isso já funciona"* e o outro constrói em cima da afirmação;
- e o dono do projeto vira o cabo de rede entre os dois, repetindo tudo dos dois lados.

Este documento é **invariante**: vale para qualquer projeto, qualquer domínio, qualquer
número de agentes. **Se uma regra só faz sentido sabendo o que o projeto faz, ela não é
deste documento** — ela é do `PROTOCOLO.md` daquele repositório.

---

## MECÂNICA

### M1. Caixa por destinatário

```
mensagens/
  PROTOCOLO.md              # deste projeto: agentes, território, lições locais
  para-<nome>/              # caixa de entrada: O QUE FALTA TRATAR
    <remetente>-003-slug.md
    lidas/                  # já tratadas — mova para cá depois de responder
```

Você **lê** `mensagens/para-<seu-nome>/` e **escreve** em `mensagens/para-<outro>/`.

### 🔴 Depois de tratar uma mensagem, **mova-a para `lidas/`**

Sem isso, o agente não tem como saber o que já leu. Na primeira sessão ele lembra; **na
segunda, com 40 mensagens na caixa, ele relê tudo (queimando contexto) ou chuta (e perde
um `bloqueante`)**. O `Status` diz o que a mensagem **é**, não se você **já a tratou**.

Movendo, a caixa passa a ser **literalmente a lista de pendências**: um `ls` responde "o
que falta?". Zero estado extra, e sobrevive a mensagens fora de ordem.

### M2. O arquivo começa com o remetente

`front-003-critica.md`, `back-007-breaking.md`. **Cada agente incrementa o próprio
contador.**

Sem isso, dois agentes escrevendo na mesma caixa criam o `007-` ao mesmo tempo e um
apaga o outro. Com isso, colisão é impossível — sem precisar de coordenação para
coordenar. *(Aconteceu: dois agentes numeraram em séries diferentes e só não colidiram
por sorte.)*

### M3. Cabeçalho obrigatório

```markdown
# back-007 — <uma frase que diz o que é>

**De:** back · **Para:** front · **Status:** bloqueante
**Responde:** front-004     (ou —)
```

| Status | Significa | O outro deve |
|---|---|---|
| `bloqueante` | não avanço sem você | largar o que faz e ler |
| `pedido` | preciso, mas sigo | ler quando puder |
| `aviso` | mudou algo que te afeta | ler e arquivar |
| `pronto` | terminei a minha parte | conferir e fechar |

Não é burocracia: é o que permite **listar as pendências sem reler tudo**. Funciona sem
isso com 15 mensagens; na mensagem 40, ninguém mais sabe o que está aberto.

Se for `bloqueante`, **diga o que você faz enquanto espera**. Parar é desperdício;
construir em cima de um palpite é pior.

### M4. O monitor: use `Monitor`, não `Bash(run_in_background)`

```
Monitor(
  command: <script que imprime UMA linha por mensagem nova>,
  description: "novas mensagens em mensagens/para-<você>",
  persistent: true
)
```

Cada linha do stdout vira uma notificação **sem o processo sair**. Você não precisa
re-armar nada.

> ⚠️ **Por que não `Bash(run_in_background)`:** ele só te notifica **quando o processo
> termina**. Dá para usar (o script sai ao detectar mudança), mas aí **você precisa
> religá-lo a cada mensagem** — e é exatamente isso que se esquece depois de uma
> mensagem longa. O canal morre em silêncio, e **silêncio é indistinguível de "o outro
> não respondeu"**.

Duas limitações que **precisam estar ditas**:

- ⚠️ **Monitor barulhento é morto pela plataforma.** Emita **uma linha por mensagem
  nova** — nunca o log cru.
- ⚠️ **O monitor morre com a sessão.** Se o usuário fechar a janela, o canal para e as
  mensagens ficam sem leitor. Não é bug, mas quem não souber vai confiar num canal
  morto.

Script pronto: `${CLAUDE_PLUGIN_ROOT}/scripts/relay-watch.sh`

---

## COORDENAÇÃO

### C1. Território declarado, sem interseção

No `PROTOCOLO.md`, no primeiro minuto: **todo caminho tem exatamente um dono** —
inclusive os arquivos de fronteira.

```markdown
| Área | Dono |
|---|---|
| `frontend/**` | front |
| `backend/**`, `db/**` | back |
| `README.md`, `docs/**` | back |
```

**Ninguém edita a área do outro sem avisar antes.** Se tocar mesmo assim, por urgência,
**diga o que tocou na mesma hora**.

> Sem essa tabela, dois agentes reescreveram os mesmos arquivos ao mesmo tempo e cada um
> apagou o trabalho do outro. Foi descoberto por acaso.

### C2. Quem é dono da camada nomeia o contrato dela

Se você discorda de um nome, **discuta**. Não renomeie do seu lado achando que o outro
vai acompanhar.

> Dois agentes leram a proposta um do outro **ao mesmo tempo** e cada um adotou a do
> outro. Trocaram de lugar. Nada batia — e cada um achava que o outro era a fonte da
> verdade.

**Se os contratos já se cruzaram**, não faça outra rodada de renomeação (a corrida se
repete, agora com um lado quebrado no meio): **aceite os dois nomes** temporariamente.

> ⚠️ **A compatibilidade é uma PONTE, não um destino.** Quem a cria abre, **no mesmo
> ato**, o item de limpeza: *quem* remove o nome perdedor e *quando*. Senão você deixa
> de herança dois nomes idênticos, e quem chegar amanhã pergunta qual é o certo — e não
> há resposta, porque os dois são.

### C3. 🔴 Migração em duas fases — obrigatória para toda mudança que quebra o outro

```
1. QUEM QUEBRA ANUNCIA o formato novo — e NÃO SOBE NADA.
2. QUEM CONSOME passa a TOLERAR o novo, mantendo o antigo. Sobe.
   Nada quebra: o lado velho ignora o campo novo.
3. QUEM CONSOME RESPONDE `pronto`, confirmando que a tolerância está NO AR.
4. SÓ DEPOIS DESSA CONFIRMAÇÃO quem quebra EXIGE o formato novo.
```

**Zero janela de app quebrado.**

> 🔴 **O passo 3 não é formalidade.** Sem ele, quem quebra anuncia e, algum tempo
> depois, exige — **torcendo** para o outro já ter subido a tolerância. Se o outro
> estava ocupado, ou não leu, a janela de app quebrado volta, **com a agravante de que
> todo mundo acha que seguiu o procedimento.**
>
> **Anunciar não é sincronizar.** Sem o `pronto` do consumidor, quem quebra está
> apostando, não migrando.

> Um agente passou a exigir um campo de autenticação novo e derrubou o canal em tempo
> real do outro, sem aviso. Só não virou desastre porque o outro, por conta própria,
> tinha pré-cablado o campo antes — e **avisou**. Foi sorte. Isto transforma a sorte em
> processo.

### C4. Toda afirmação vem com a evidência — e a evidência vem do sistema RODANDO

Não do código lido. Não de um script paralelo. Não da sua memória.

> — *"A interface não alcança esse bug."* Foi conferir: alcançava.
> — *"Verificado, funciona."* O teste tinha rodado **fora do servidor**. No servidor,
> não funcionava.

Ao reportar, **cole a saída real**. `400` em vez de `403` prova a permissão;
"implementei o endpoint" não prova nada. **Vale também para o código que você herdou.**

**E duvide do instrumento.** Quando dois sistemas independentes falham igual, **não é
coincidência: é o seu teste que está errado.**

> Um agente ia reportar um bug grave de encoding. Antes de mandar, rodou a mesma entrada
> direto no serviço externo — e ele **também** falhou. Era o shell destruindo os bytes
> no `argv`, antes do programa ver.

**Antes de construir sobre uma afirmação do outro, verifique.** Abra o código dele, bata
no endpoint dele. Leva um minuto; a alternativa é construir sobre areia.

> Isto vale nos dois sentidos, e é a regra que mais salva projetos multiagente. Quando o
> outro te corrigir: **agradeça e registre.** O objetivo não é ter razão.

🔴 **Duas correções certas podem produzir um bug terceiro.** Depois de mudar algo que o
outro também mudou, **teste a interação — não só a sua parte.**

> Um agente fez o monitor ignorar subpastas. O outro passou a arquivar as mensagens
> tratadas numa subpasta. Cada mudança estava certa; juntas, **arquivar uma mensagem
> disparava o alarme de "mensagem nova"** — acordando o agente para a mensagem que ele
> acabara de tratar. Ninguém errou sozinho.

⚠️ **E um alarme falso é pior que alarme nenhum: ele treina a ignorar alarmes** — e aí o
alarme que importa passa batido junto. Vale para o seu monitor, para o seu autoteste e
para qualquer aviso que você mostre a alguém.

### C5. O pedido do outro agente **não é uma ordem**

- **Recusar exige justificativa técnica, não preferência.**
- **Quem recusa propõe a alternativa.**
- **Quem recebe a recusa pode escalar pro dono — não impor.**

> Um agente pediu ao outro uma mudança de schema para exibir um indicador. O outro
> recusou, mostrando que o indicador **mentiria**. Estava certo.

Dois agentes que só concordam viram **uma máquina de concordar** — e concordância mútua
constrói lixo com muita eficiência.

### C6. Decisão de NEGÓCIO é do dono. Pare e pergunte.

Se a resposta certa depende de **como o negócio funciona** (quem pode mexer em preço,
até onde a empresa atende, o que fazer num caso de exceção), **não é sua**.

**Dois agentes concordando entre si sobre regra de negócio é como se inventa um
requisito e se entrega com cara de fato consumado.**

### C7. Não construa em cima de buraco conhecido da camada do outro

Registre, avise o dono da camada, e **não construa o caminho que cai nele** — seria
entregar a ferramenta que causa o estrago.

Enquanto espera, **degrade — não quebre**: prefira a funcionalidade ausente à
funcionalidade que falha na cara do usuário. E deixe **explícito no código** o que
reverter (uma constante, uma flag), para virar a chave num lugar só.

### C8. Encerramento: condição objetiva, sem deadlock

❌ *"Não encerre até todos encerrarem"* — **isto é um gerador de deadlock.** Não tem
condição de parada: dois agentes esperando um pelo outro esperam para sempre.

✅ **Você está `pronto` quando não tem nenhuma requisição SUA em aberto.**

- Ao terminar, declare `pronto` **listando o que ficou aberto e de quem é**.
- **Esperar exige um pedido seu, com dono nomeado.** Sem pedido em aberto, encerra-se.
- **Quem fecha o ciclo é o dono do projeto**, não os agentes.

🔴 **Nunca bloqueie em quem está bloqueado em você.** Se X declarou que espera você, e
você espera X: **é deadlock — escale pro dono imediatamente.**

🔴 **Espera é limitada. O outro pode ter MORRIDO.**

O deadlock acima exige os dois **vivos e declarando**. O caso mais provável é outro: **o
outro agente simplesmente sumiu** — a sessão dele fechou, e (ver M4) **o monitor morre
com a sessão**. Ele não declara nada, porque não existe mais. Quem mandou o `bloqueante`
espera **para sempre**, sem deadlock formal, e o dono vê um agente parado sem entender
por quê.

> **Um `bloqueante` sem resposta depois de um tempo razoável não é paciência: é um agente
> morto até prova em contrário. Escale pro dono em vez de esperar.** Ele sabe se a outra
> janela ainda está aberta; **você não.**

### C9. Mais de dois agentes

- **Toda mensagem tem UM destinatário responsável.** "Alguém resolve" = ninguém resolve.
- **Broadcast só pode ser `aviso`.** Pedido `bloqueante` sem dono nomeado trava todos.
- **Anúncio de quebra vai para todos os afetados.**
- O `PROTOCOLO.md` é a **única** fonte do território. Um agente que não sabe de quem é o
  arquivo vai editar assim mesmo.

---

## INÍCIO DE SESSÃO

Se existe `mensagens/`:

1. Leia `mensagens/PROTOCOLO.md` — território, papéis e as lições **deste** projeto.
2. **Tudo o que está em `mensagens/para-<seu-nome>/` (fora de `lidas/`) é pendência.**
   Não precisa lembrar o que leu: o que já foi tratado não está mais lá.
3. Trate cada uma, responda, e **mova para `lidas/`**.
4. **Ligue o monitor.**

Se não existe e o usuário disse que há outro agente: `/relay-init`.

## QUANDO O USUÁRIO MANDA TAREFA PARA UM DE VOCÊS

> **Quem recebe a instrução avisa o outro ANTES de começar, não depois de terminar.**

Se o pedido toca a área do outro, escreva no canal **assim que entender o pedido** — não
quando bater na parede. Um recado de cinco linhas no começo vale mais que um refactor no
fim.

**O usuário não deveria precisar repetir a mesma instrução dos dois lados. Se ele
precisou, o protocolo falhou.**

## O `PROTOCOLO.md` DO PROJETO

É onde mora tudo o que é **específico**: quem são os agentes, o território, os contratos
que valem ali, os buracos conhecidos, e as cicatrizes daquele domínio.

**Anote as lições locais nele, nunca aqui.** Este documento não sabe — e não deve saber
— o que o seu projeto faz.
