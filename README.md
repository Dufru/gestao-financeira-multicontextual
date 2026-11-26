# Gestão Financeira Multicontextual

Aplicativo Android em Flutter para registrar receitas e despesas em três contextos separados: **Pessoal**, **Profissional** e **Conjunto**. Os dados ficam em um banco SQLite local no aparelho.

## O que o aplicativo faz

- Alterna entre os contextos financeiro pessoal, profissional e conjunto.
- Mostra entradas, saídas e saldo do mês do contexto selecionado, além do consolidado mensal.
- Cadastra, edita, filtra e exclui lançamentos com descrição, valor, categoria e data.
- Separa os lançamentos por contexto e valida os campos antes de salvar.
- Registra despesas compartilhadas no contexto Conjunto e calcula o acerto igualitário entre “Você” e “Outra pessoa”, sem perder centavos no rateio.
- Persiste os dados no aparelho, inclusive após fechar e abrir o aplicativo.

O projeto ainda não oferece login, sincronização entre aparelhos, cadastro de participantes ou ajuste de percentuais do rateio. As despesas compartilhadas usam divisão 50/50.

## Tecnologias e arquitetura

- Flutter e Dart, com interface Material 3.
- MVVM: telas em `lib/views/` e estado/orquestração em `lib/viewmodels/` usando `ChangeNotifier`.
- Repositórios em `lib/repositories/` isolam o acesso às tabelas SQLite.
- `sqflite` mantém perfis, categorias, lançamentos e despesas compartilhadas no dispositivo. Valores monetários são armazenados em centavos inteiros.
- `lib/logica/` contém regras Dart sem dependência de tela para seleção de perfil, saldos e divisão de despesas.
- `test/` contém testes de widgets, persistência, repositórios e regras de negócio.

### Estrutura principal

```text
lib/
  database/       abertura, criação e migração do SQLite
  logica/         perfil ativo, saldo e rateio
  models/         modelos de persistência
  repositories/   consultas e gravações
  utils/          formatação de valores e datas
  viewmodels/     estado e operações da aplicação
  views/          resumo, movimentos, contextos e formulários
test/
  logica/         testes das regras de domínio
  app_database_test.dart
  widget_test.dart
docs/LOGICA.md    detalhes das regras de saldo e rateio
```

## Requisitos

- Flutter SDK com Dart **3.13.7 ou superior**, conforme a restrição em `pubspec.yaml`.
- Android Studio e Android SDK configurados.
- JDK 17 ou superior.
- Emulador Android ou aparelho com depuração USB habilitada.

Confira a instalação antes de executar:

```bash
flutter doctor -v
```

## Clonar e executar

```bash
git clone https://github.com/Dufru/gestao-financeira-multicontextual.git
cd gestao-financeira-multicontextual
flutter pub get
flutter run
```

Para escolher um dispositivo conectado:

```bash
flutter devices
flutter run -d ID_DO_DISPOSITIVO
```

No Android Studio, abra a pasta clonada como projeto Flutter, aguarde a resolução das dependências, selecione um emulador ou aparelho e pressione **Run**.

## Executar os testes

```bash
flutter test
```

O conjunto de testes cobre criação do banco e dados iniciais, operações de repositório, isolamento entre perfis, cálculo de saldos, rateio igualitário e telas principais. O teste SQLite usa `sqflite_common_ffi` no ambiente de testes.

## Fluxo recomendado para demonstração

1. Abra **Resumo** e alterne entre Pessoal, Profissional e Conjunto.
2. Registre uma entrada ou saída, preenchendo valor, descrição, categoria e data.
3. Mostre a atualização dos valores do mês e a separação dos lançamentos.
4. Em **Contextos**, selecione Conjunto e abra a divisão de despesas.
5. Registre uma despesa paga por uma das pessoas e mostre o acerto calculado.
6. Reabra o aplicativo para demonstrar que os dados permanecem no aparelho.

## Observações sobre dados

O banco inicializa os três perfis e nove categorias na primeira abertura. A versão 2 do banco adiciona a tabela de despesas compartilhadas e migra automaticamente bancos criados pela versão 1, preservando os lançamentos existentes. Os dados são locais e não são enviados para um servidor.

## Documentação complementar

- [Lógica de negócio, saldo consolidado e rateio](docs/LOGICA.md)
- [Documentação Técnica de Implementação e Testes (Bloco 3)](docs/DOCUMENTACAO_TECNICA_BLOCO3.md)

## Contexto acadêmico e equipe

Projeto semestral desenvolvido para a disciplina **Desenvolvimento Mobile Nativo (SIS918)** do curso de **Sistemas de Informação** da **UNEX — Centro Universitário de Excelência de Vitória da Conquista**, sob orientação do Prof. **Wallas Froes de Oliveira**.

**Integrantes:**
- Danilo Motta Rodrigues
- Emanuel dos Santos Amaral Nascimento
- Gabriel da Silva Carvalho
- Matheus Vinícius Duarte Costa
- Pedro Santos Simões da Silva
- Vitor Hugo Lima Silva Bittencourt
