# Gestao Financeira Multicontextual

Projeto acadêmico desenvolvido para a disciplina de Desenvolvimento Mobile Nativo (5º Semestre - Sistemas de Informação - Unex). A aplicação consiste em um sistema de controle financeiro móvel com suporte a múltiplos perfis de isolamento e compartilhamento de contas (Pessoal, Profissional e Conjunto).

---

## 1. Arquitetura do Sistema

A aplicação adota o padrão de arquitetura **MVVM (Model-View-ViewModel)** integrado ao padrão **Repository** e suporte à biblioteca **Room Database** para persistência local de dados.

### Divisão de Responsabilidades
* **Pedro:** Modelagem do banco de dados local (Room), DAOs, repositório e testes de persistência.
* **Danilo:** Lógica de perfil ativo (Pessoal, Profissional, Conjunto), cálculo de saldo consolidado e rateio de despesas.
* **Emanuel:** Interface gráfica, componentes visuais, cadastro de lançamentos e painel geral.
* **Vitor Hugo:** Controle de versão no GitHub, resolução de conflitos de código, guia de execução em ambiente limpo, documentação técnica e arquitetura.

---

## 2. Guia de Reprodução e Configuração

Instruções técnicas para clonagem, compilação e execução do projeto a partir de um ambiente limpo.

### Requisitos Mínimos
* **JDK:** Versão 17 ou superior.
* **Android Studio:** Ladybug ou versão mais recente equivalente.
* **Android SDK:** Target API Level 34 (Android 14) / Minimum API Level 26.
* **Dispositivo de Teste:** Emulador AVD ou dispositivo físico com modo de Depuração USB ativo.

### Procedimento de Execução

1. **Clonar o repositório:**
   ```bash
   git clone https://github.com/Dufru/gestao-financeira-multicontextual
   cd gestao-financeira-multicontextual



2. **Abertura do Projeto:**
* Abrir o Android Studio.
* Selecionar a opção `Open` e indicar o diretório raiz do projeto clonado.
* Aguardar o término da sincronização das dependências via Gradle (`Gradle Sync`).


3. **Compilação e Execução:**
* Selecionar o target (emulador ou dispositivo físico).
* Executar a compilação por meio da opção `Run` (`Shift + F10`).



---

## 3. Estrutura de Testes Automatizados

O projeto utiliza testes unitários e de integração para validação da camada de persistência e das regras de consolidação financeira.

### Escopo dos Testes

* **Testes do Banco de Dados (Room InMemory):** Validação das operações de escrita e leitura dos DAOs, além do isolamento dos lançamentos por perfil.
* **Testes da Lógica de Negócio (JUnit):** Validação dos algoritmos de consolidação de saldo (evitando dupla contagem) e lógica de divisão no perfil conjunto.

Para executar a suíte de testes via linha de comando:

bash
./gradlew test
