# Documentação Técnica de Implementação e Testes — Bloco 3

**Projeto:** Gestão Financeira Multicontextual (Pessoal, Profissional e Conjunto)  
**Disciplina:** Desenvolvimento Mobile Nativo (SIS918) — Sistemas de Informação (UNEX)  
**Orientador:** Prof. Wallas Froes de Oliveira  
**Equipe:** Danilo Motta Rodrigues, Emanuel dos Santos Amaral Nascimento, Gabriel da Silva Carvalho, Matheus Vinícius Duarte Costa, Pedro Santos Simões da Silva, Vitor Hugo Lima Silva Bittencourt.

---

## 1. Arquitetura de Implementação

O aplicativo foi estruturado em **Flutter/Dart** utilizando o padrão **MVVM (Model–View–ViewModel)** aliado ao padrão **Repository**, com persistência local embarcada em **SQLite** (`sqflite`) e regras de domínio desacopladas da camada de interface.

### 1.1 Organização dos diretórios

| Camada / Diretório | Responsabilidade | Principais arquivos |
|---|---|---|
| **Entrada da aplicação** | Inicialização do binding Flutter e montagem do widget raiz | `lib/main.dart` |
| **Views (`lib/views/`)** | Interface Material 3, navegação por abas, formulários com validação e feedback visual | `finance_home.dart`, `joint_expenses_page.dart`, `transaction_form_sheet.dart`, `transaction_tile.dart` |
| **ViewModels (`lib/viewmodels/`)** | Gerenciamento de estado reativo via `ChangeNotifier`, carregamento assíncrono e coordenação entre repositórios e domínio | `finance_view_model.dart` |
| **Domínio (`lib/logica/`)** | Regras puras em Dart para seleção de perfil ativo, cálculo de saldo sem dupla contagem e rateio igualitário/proporcional em centavos inteiros | `logica.dart`, `perfil.dart`, `perfil_ativo.dart`, `modelos.dart`, `saldo.dart`, `divisao_conjunto.dart` |
| **Models (`lib/models/`)** | Estruturas de dados persistidas e conversão `toMap` / `fromMap` | `perfil.dart`, `categoria.dart`, `transacao.dart`, `resumo_financeiro.dart`, `despesa_compartilhada.dart` |
| **Repositories (`lib/repositories/`)** | Isolamento das consultas SQLite por entidade e agregação de saldos | `perfil_repository.dart`, `categoria_repository.dart`, `transacao_repository.dart`, `saldo_repository.dart`, `despesa_compartilhada_repository.dart` |
| **Banco de Dados (`lib/database/`)** | Abertura, criação de tabelas, chaves estrangeiras, índices, seed inicial e migração (v1 → v2) | `app_database.dart` |
| **Utilitários (`lib/utils/`)** | Formatação monetária em Real (`R$`), parsing seguro para centavos e formatação de datas | `formatters.dart` |

### 1.2 Decisões técnicas de destaque

- **Valores monetários em centavos inteiros (`int`)**: todas as transações, saldos e rateios operam exclusivamente com inteiros, eliminando erros de arredondamento de ponto flutuante (`double`).
- **Isolamento por contexto**: toda transação possui chave estrangeira obrigatória `perfil_id` referenciando a tabela `perfil` (`Pessoal`, `Profissional` ou `Conjunto`), garantindo separação real nas consultas (`WHERE perfil_id = ?`).
- **Rateio sem perda de centavos**: no contexto Conjunto, `calcularAcerto` em `lib/logica/divisao_conjunto.dart` soma todas as despesas do período e distribui o resto da divisão inteira um centavo por vez para os maiores restos, assegurando que a soma dos acertos seja sempre exata.
- **Migração incremental de banco**: a versão 2 de `AppDatabase` adiciona a tabela `despesa_compartilhada` via `onUpgrade` sem perda de lançamentos existentes na versão 1.

---

## 2. Guia de Reprodução e Configuração

### 2.1 Pré-requisitos

- **Flutter SDK** compatível com **Dart >= 3.13.7** (conforme `pubspec.yaml`).
- **Android Studio** com Android SDK configurado e **JDK 17+**.
- **Git** instalado e emulador Android configurado ou dispositivo físico com depuração USB ativada.

### 2.2 Passo a passo para clonar, configurar e executar

1. **Verificar o ambiente Flutter:**
   ```bash
   flutter doctor -v
   ```

2. **Clonar o repositório e entrar na pasta do projeto:**
   ```bash
   git clone https://github.com/Dufru/gestao-financeira-multicontextual.git
   cd gestao-financeira-multicontextual
   ```

3. **Instalar as dependências do `pubspec.yaml`:**
   ```bash
   flutter pub get
   ```

4. **Executar a análise estática e a suíte de testes:**
   ```bash
   flutter analyze
   flutter test
   ```

5. **Executar o aplicativo em emulador ou dispositivo Android:**
   ```bash
   flutter devices
   flutter run
   ```

6. **Gerar o APK de entrega (release):**
   ```bash
   flutter build apk --release
   ```
   O arquivo gerado ficará disponível em `build/app/outputs/flutter-apk/app-release.apk`.

---

## 3. Metodologia e Resultados dos Testes

A estratégia de validação foi dividida em quatro frentes automatizadas utilizando `flutter_test` e `sqflite_common_ffi`:

| Arquivo de Teste | Escopo Validado | Cenários Cobertos |
|---|---|---|
| `test/logica/perfil_ativo_test.dart` | Regras de alternância de contexto | Perfil inicial padrão (`Pessoal`), emissão de notificação apenas na troca efetiva, filtragem de contas e transações visíveis por perfil |
| `test/logica/saldo_test.dart` | Integridade do saldo consolidado | Saldo por conta e por perfil, prevenção de dupla contagem em transferências internas, remoção de IDs duplicados, patrimônio do usuário e resumo por período |
| `test/logica/divisao_conjunto_test.dart` | Rateio e acerto de despesas | Divisão igualitária (50/50), percentual (60/40) e proporcional à renda, preservação exata de centavos ímpares, detecção de pagador inválido e simplificação de acertos |
| `test/app_database_test.dart` | Persistência SQLite e repositórios | Criação dos 3 perfis e 9 categorias iniciais, restrições `FOREIGN KEY` e `CHECK` (valores positivos e tipos válidos), CRUD de transações e despesas compartilhadas, isolamento entre perfis e cálculo de saldo consolidado |
| `test/formatters_test.dart` | Utilitários de entrada e exibição | Formatação de centavos para padrão brasileiro (`R$ 1.234.567,89`) e parsing de entradas digitadas pelo usuário |
| `test/widget_test.dart` | Interface e fluxos principais | Renderização da visão geral, listagem de lançamentos na aba Movimentos, troca para aba Contextos e exibição do acerto pendente na tela de Despesas Compartilhadas |

---

## 4. Referências e Rastreabilidade

- BRASIL. **Lei nº 13.709, de 14 de agosto de 2018 (LGPD)**. Lei Geral de Proteção de Dados Pessoais. Brasília, DF, 2018.
- DART. **Dart documentation**. Google, 2026. Disponível em: https://dart.dev/.
- FLUTTER. **Flutter documentation — Guide to app architecture (MVVM)**. Google, 2026. Disponível em: https://docs.flutter.dev/.
- PRESSMAN, R. S.; MAXIM, B. R. **Engenharia de software: uma abordagem profissional**. 9. ed. Porto Alegre: AMGH, 2021.
- ROCHA, H. **Gerenciamento de estado em Flutter com Riverpod**. São Paulo: Casa do Código, 2022.
- SOMMERVILLE, I. **Engenharia de software**. 10. ed. São Paulo: Pearson, 2019.
- Documentação interna complementar: [`docs/LOGICA.md`](LOGICA.md).
