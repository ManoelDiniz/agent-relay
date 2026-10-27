# /relay-init

Abre o canal entre os agentes que estão trabalhando neste repositório.

## Uso

```
/relay-init <seu-nome> <nome-do-outro> [mais-nomes...]
```

## 🔴 Não adivinhe os agentes. **Pergunte.**

Não assuma "front" e "back" — podem ser quatro agentes (`dados`, `infra`, `mobile`,
`docs`), ou dois agentes na mesma camada. Se o usuário não passou os nomes, **pergunte**:

- Quantos agentes vão trabalhar neste repo?
- Como cada um se chama, e **qual a área de cada um**?
- Quem é você nessa divisão?

Use nomes de **camada ou responsabilidade** — o nome vira o território.

## O que fazer

1. Carregue a skill `agent-relay` (o protocolo inteiro está lá).

2. Crie uma caixa por agente:
   ```
   mensagens/para-<cada-nome>/
   ```

3. Crie `mensagens/PROTOCOLO.md`. **É aqui que mora tudo o que é deste projeto** — a
   skill é genérica e não sabe nada do seu domínio.

   - **Tabela de território**: olhe a árvore de diretórios real e escreva quem é dono de
     quê. **Todo caminho tem exatamente um dono**, inclusive os de fronteira. Marque como
     *proposta*, para os outros confirmarem.
   - **Contratos** que atravessam as camadas (API, schema, eventos) e **quem os nomeia**.
   - **Buracos conhecidos** — o que ainda não pode ser usado, e por quê.
   - **Lições deste domínio**, conforme aparecerem. Anote-as aqui, **nunca na skill**.

4. Escreva a sua primeira mensagem em `mensagens/para-<outro>/<seu-nome>-001-...md`:
   - quem você é e qual a sua área;
   - o que você já **verificou** do projeto (o que está no ar, o que compila);
   - **o território que você propõe** — peça confirmação;
   - o que você já sabe que vai precisar dele.

5. **Ligue o monitor** (ferramenta `Monitor`, não `Bash` em background):
   ```
   Monitor(
     command: 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/relay-watch.sh" mensagens/para-<seu-nome>',
     description: "novas mensagens em mensagens/para-<seu-nome>",
     persistent: true
   )
   ```

6. Diga ao usuário que o canal está aberto, que ele pode dar a instrução a **um só** de
   vocês — e **avise que o monitor morre quando ele fechar a janela**.

## Cuidado

Se já existir um canal com outro nome (`dialogo_*`, `relay/`, `msgs/`), **não crie outro
em paralelo**: use o que existe, ou proponha a migração ao outro agente **pelo canal
atual**, antes de mover qualquer coisa.

**Dois canais é o mesmo que nenhum.**
