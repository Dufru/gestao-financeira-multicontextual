# Lógica do app

Esta seção descreve as regras de negócio do app: perfil ativo, saldo consolidado e divisão do perfil Conjunto. O código está em `lib/logica/` e os testes em `test/logica/`.

## 1. Convenções

- **Dinheiro em centavos inteiros** (`R$ 10,50` = `1050`). Nenhuma conta usa `double`, então não há erro de arredondamento nas somas.
- **Uma conta pertence a exatamente um perfil** (Pessoal, Profissional ou Conjunto). Essa regra é a base do saldo consolidado.
- A lógica é Dart puro, sem dependência de tela. A única exceção é `PerfilAtivoController`, que usa `ChangeNotifier`.

## 2. Perfil ativo

Os três perfis são `Pessoal`, `Profissional` e `Conjunto` (`enum Perfil`).

`PerfilAtivoController` guarda o perfil selecionado (padrão: Pessoal) e filtra o que a tela mostra:

| Método | Resultado |
|---|---|
| `selecionar(perfil)` | Troca o perfil e notifica a interface. Não notifica se o perfil for o mesmo. |
| `contasVisiveis(contas)` | Só as contas do perfil ativo. |
| `transacoesVisiveis(contas, transacoes)` | Transações cuja origem **ou destino** é uma conta do perfil ativo. |

Uma transferência entre perfis aparece nos dois perfis envolvidos. Isso vale só para exibição. Nenhum saldo é calculado somando transações da lista visível.

Uso na tela:

```dart
final perfil = PerfilAtivoController();
ListenableBuilder(
  listenable: perfil,
  builder: (_, __) => Text(perfil.ativo.rotulo),
);
```

## 3. Saldo consolidado

### Por que não há dupla contagem

O saldo é sempre calculado **por conta** e depois somado, nunca a partir de totais de perfil nem de listas de transações de telas diferentes. Cada conta tem um único perfil, então entra uma vez só na soma.

```
saldo da conta = saldo inicial + receitas − despesas + transferências recebidas − transferências enviadas
saldo consolidado = soma do saldo de todas as contas (cada uma uma vez)
```

Garantias:

- **Transferência interna não altera o consolidado.** Uma ponta debita, a outra credita, e o total fica igual. Ela só muda o saldo de cada perfil.
- **Dados repetidos são ignorados.** Conta ou transação com o mesmo `id` é contada uma vez, por exemplo se vier de duas listas diferentes.
- **Referência inválida falha cedo.** Transação que aponta para conta inexistente gera `ArgumentError`.

### API (`CalculadoraSaldo`)

| Método | O que devolve |
|---|---|
| `saldoConta(id)` | Saldo de uma conta. |
| `saldoDoPerfil(perfil)` | Soma das contas daquele perfil. |
| `saldoConsolidado()` | Soma de todas as contas. |
| `patrimonioDoUsuario(id, divisao)` | Pessoal + Profissional + **a parte do usuário** no Conjunto. |
| `resumo({perfil, inicio, fim})` | Receitas, despesas e transferências do período `[inicio, fim)`. |

**Consolidado × patrimônio do usuário:** o consolidado soma o Conjunto inteiro. O patrimônio do usuário soma só a parte dele, conforme a divisão. Use o consolidado para o total movimentado no app e o patrimônio para "quanto eu tenho".

**Resumo do período:** transferências entre contas dentro do escopo (um perfil ou todos) se anulam e não aparecem. Só as que cruzam a fronteira do escopo aparecem, como `transferenciasEntrada` e `transferenciasSaida`. A `variacao` (receitas − despesas + entradas − saídas) bate com a diferença de saldo no período.

## 4. Divisão do perfil Conjunto

### Como a divisão é definida (`DivisaoConjunto`)

- `igualitaria(['ana', 'bob'])`: partes iguais (50/50 com dois participantes).
- `percentuais({'ana': 60, 'bob': 40})`: percentuais explícitos, que devem somar 100.
- `proporcionalARenda({'ana': renda1, 'bob': renda2})`: proporcional à renda.

### Rateio sem perder centavo (`ratear`)

`ratear(valor, pesos)` divide um valor em centavos proporcionalmente aos pesos. A soma do resultado é **sempre igual ao valor original**. Cada participante recebe a parte inteira da sua cota. Os centavos que sobram vão um a um para quem tem o maior resto da divisão, e em empate para quem vem primeiro na lista.

Exemplo: R$ 1,00 entre 3 pessoas resulta em 34 + 33 + 33 centavos.

### Acerto de contas (`calcularAcerto`)

Quando alguém paga do próprio bolso uma despesa do Conjunto (`DespesaCompartilhada`), a despesa **não altera o saldo de nenhuma conta**. Ela só gera um acerto entre os participantes.

1. Soma o que cada um pagou (`pago`).
2. Rateia o **total** das despesas pela divisão (`devido`). Rateia-se o total, e não despesa a despesa, para o arredondamento não acumular.
3. `saldoLiquido = pago − devido`. Positivo significa que a pessoa tem a receber, negativo que tem a pagar. A soma é sempre zero.
4. Gera a lista de pagamentos (`acertos`): os maiores devedores pagam aos maiores credores até zerar tudo.

Exemplo: Ana, Bob e Cris dividem igualmente, e Ana paga R$ 900,00. Cada um deve R$ 300,00. Resultado: Bob → Ana R$ 300,00 e Cris → Ana R$ 300,00.

Despesas repetidas (mesmo `id`) são contadas uma vez. Pagador que não está na divisão gera `ArgumentError`.

## 5. Testes

Rodam com `flutter test test/logica/`.

| Arquivo | O que cobre |
|---|---|
| `saldo_test.dart` | Saldo por conta e por perfil, consolidado sem dupla contagem (transferência interna, id duplicado, conta duplicada), patrimônio do usuário, resumo por período e validações. |
| `divisao_conjunto_test.dart` | Rateio (soma exata, resto, valor negativo, peso zero), os três tipos de divisão e o acerto de contas (2 e 3 pessoas, 60/40 com centavo ímpar, quite, duplicata, pagador inválido). |
| `perfil_ativo_test.dart` | Perfil inicial, notificação ao trocar, filtro de contas e transações. |

## 6. Decisões em aberto

As premissas abaixo foram assumidas e podem ser trocadas sem mexer no resto:

- Saldo consolidado soma o Conjunto inteiro, e o patrimônio do usuário soma só a parte dele.
- Divisão padrão 50/50, configurável por percentual ou por renda.
- Despesas pagas do bolso geram acerto, mas não movimentam contas.
- A escolha do perfil ativo **não é persistida** entre sessões (por exemplo com `shared_preferences`).
