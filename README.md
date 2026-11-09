# WhoPlay

**Encontra. Marca. Joga.**

Projeto Multidisciplinar — Desenvolvimento de uma aplicação móvel em Flutter.

## Grupo 6

| Nome | Número |
|---|---:|
| Cristiano Cordeiro | 20251285 |
| Hélio José | 20250953 |
| Sebastião Cardoso | 20251225 |
| Tchali Tchalimba | 20252440 |

**Repositório:** https://github.com/tchaliuziel/WhoPlay-app

---

## 1. Tema e descrição do projeto

O **WhoPlay** é uma aplicação móvel desenvolvida em Flutter que permite encontrar pessoas para praticar desporto, organizar jogos e participar em atividades desportivas.

A aplicação liga jogadores com base em critérios como:

- Modalidade desportiva;
- Localização e distância;
- Nível de experiência;
- Disponibilidade;
- Objetivos desportivos.

O objetivo é facilitar a organização de atividades desportivas, aproximando pessoas com interesses e características compatíveis.

Entre as modalidades consideradas encontram-se Padel, Ténis, Futebol, BJJ, Basquetebol, Voleibol, Corrida e Fitness.

## 2. Tecnologias utilizadas

| Tecnologia | Utilização |
|---|---|
| Flutter | Desenvolvimento da aplicação móvel |
| Dart | Linguagem de programação do frontend |
| Node.js | Ambiente de execução do backend |
| Express.js | Desenvolvimento da API REST |
| MySQL / MariaDB | Sistema de gestão da base de dados |
| XAMPP | Ambiente local para execução do MySQL |
| Git e GitHub | Controlo de versões e partilha do código |
| Visual Studio Code | Ambiente de desenvolvimento |

## 3. Organização da aplicação

A aplicação abre no ecrã de Login. Após autenticação, o utilizador tem acesso a cinco entradas principais na barra de navegação inferior.

| Entrada | Funcionalidade |
|---|---|
| Explorar | Encontrar jogadores e consultar o mapa |
| Jogos | Consultar jogos disponíveis e histórico |
| Criar (+) | Criar um novo jogo |
| Inbox | Consultar convites e notificações |
| Perfil | Consultar e editar os dados do utilizador |

### Ecrãs e funcionalidades

| Nº | Ecrã | Como se chega |
|---|---|---|
| 01 | Login | Ecrã inicial e depois de terminar sessão |
| 02 | Registo e onboarding | Login → Criar conta |
| 03 | Perfil | Separador Perfil |
| 04 | Encontrar jogadores | Explorar → Jogadores |
| 05 | Perfil do jogador | Jogadores → Ver perfil |
| 06 | Convites e notificações | Inbox |
| 07 | Criar jogo | Botão central (+) |
| 08 | Mapa | Explorar → Mapa |
| 09 | Detalhe do jogo | Consultar um jogo |
| 10 | Check-in por QR Code | Detalhe do jogo → Check-in |
| 11 | Histórico | Jogos → Histórico |

O ecrã de registo permite criar uma conta e selecionar modalidades desportivas. O histórico permite consultar os jogos em que o utilizador participou ou que organizou.

## 4. Funcionalidades implementadas

A aplicação integra funcionalidades de autenticação, gestão de perfil, pesquisa de jogadores e organização de jogos.

### 4.1 Autenticação e utilizadores

- Registo de novos utilizadores;
- Início e encerramento de sessão;
- Autenticação através da API;
- Consulta e atualização do perfil.

### 4.2 Perfil desportivo

- Atualização dos dados pessoais;
- Seleção de modalidades desportivas;
- Definição do nível de experiência;
- Definição de objetivos;
- Configuração da disponibilidade semanal.

### 4.3 Pesquisa e compatibilidade

- Consulta de jogadores;
- Pesquisa por modalidade;
- Consulta de nível e localização;
- Apresentação de jogadores compatíveis.

### 4.4 Gestão de jogos

- Criação de jogos;
- Consulta de jogos disponíveis;
- Entrada em jogos;
- Consulta de participantes;
- Consulta do histórico de jogos.

### 4.5 Convites e notificações

- Envio de convites;
- Consulta de convites recebidos;
- Aceitação e recusa de convites;
- Consulta de notificações.

### 4.6 Localização e check-in

- Consulta do mapa da aplicação;
- Consulta de jogos associados à localização;
- Geração e consulta de QR Code para check-in.

**Nota:** a utilização de GPS real, notificações push e validação presencial do check-in devem ser distinguidas das funcionalidades que já estejam efetivamente integradas e testadas no dispositivo.

## 5. Backend e API REST

O backend encontra-se na pasta `backend/` e foi desenvolvido com Node.js e Express.js.

A API disponibiliza serviços para comunicação entre a aplicação Flutter e a base de dados MySQL.

### Organização do backend

```text
backend/
├── src/
│   ├── server.js
│   ├── config/
│   ├── middleware/
│   └── routes/
│       ├── auth.js
│       ├── modalidades.js
│       ├── perfil.js
│       ├── jogadores.js
│       ├── jogos.js
│       ├── convites.js
│       └── avisos.js
├── package.json
├── package-lock.json
└── .env.example
```

### Principais recursos da API

| Recurso | Responsabilidade |
|---|---|
| Autenticação | Registo e login |
| Modalidades | Consulta e gestão das modalidades |
| Perfil | Consulta e atualização do perfil |
| Jogadores | Pesquisa e consulta de jogadores |
| Jogos | Criação, consulta e participação em jogos |
| Convites | Envio e gestão de convites |
| Avisos | Consulta de notificações |

A comunicação é realizada através de pedidos HTTP, com respostas em formato JSON. As operações protegidas utilizam autenticação por token, conforme a implementação do backend.

## 6. Base de dados

O projeto utiliza uma base de dados MySQL denominada `whoplay`.

A base de dados foi estruturada para representar os utilizadores, as modalidades desportivas, as disponibilidades e a organização dos jogos.

### Tabelas principais

| Tabela | Descrição |
|---|---|
| `utilizadores` | Dados e credenciais dos utilizadores |
| `modalidades` | Modalidades desportivas disponíveis |
| `utilizador_modalidades` | Relação entre utilizadores e modalidades, incluindo nível |
| `disponibilidades` | Horários em que os utilizadores estão disponíveis |
| `jogos` | Jogos criados pelos utilizadores |
| `jogo_participantes` | Relação entre jogos e participantes |
| `convites` | Convites enviados entre utilizadores |
| `notificacoes` | Notificações associadas às atividades da aplicação |

A estrutura utiliza relações entre tabelas para evitar duplicação desnecessária de informação e manter a integridade dos dados.

Os scripts SQL do projeto devem estar organizados da seguinte forma:

```text
database/
├── create.sql
├── populate.sql
└── queries.sql
```

- `create.sql`: criação da base de dados e das tabelas;
- `populate.sql`: inserção de dados de exemplo;
- `queries.sql`: consultas SQL utilizadas no projeto.

**Importante:** não executar scripts que eliminem a base de dados existente sem salvaguardar previamente os dados.

## 7. Instruções de execução

### 7.1 Requisitos

- Flutter SDK 3.22 ou superior;
- Dart compatível com a versão do Flutter instalada;
- Node.js e npm;
- XAMPP com MySQL/MariaDB;
- Visual Studio Code;
- Dispositivo Android, emulador ou Chrome.

### 7.2 Configuração da base de dados

1. Abrir o XAMPP.
2. Iniciar o serviço MySQL.
3. Abrir o phpMyAdmin.
4. Criar ou importar a estrutura da base de dados `whoplay`.
5. Executar os scripts de população, caso seja necessário inserir dados de demonstração.

Utilizar os scripts existentes no projeto e evitar executar novamente scripts destrutivos sobre uma base de dados que já contenha informação.

### 7.3 Configuração do backend

Abrir um terminal na pasta do backend:

```powershell
cd backend
```

Instalar as dependências:

```powershell
npm.cmd install
```

Configurar as variáveis de ambiente de acordo com o ficheiro `.env.example`, incluindo os dados de ligação à base de dados e as configurações de autenticação.

Iniciar o servidor:

```powershell
npm.cmd run dev
```

A API deverá ficar disponível em:

```text
http://localhost:3000
```

Para verificar o estado da API e da ligação à base de dados:

```text
http://localhost:3000/saude
```

O terminal do backend deve permanecer aberto enquanto a aplicação estiver a utilizar os serviços.

### 7.4 Executar a aplicação Flutter

Na pasta principal do projeto:

```powershell
flutter pub get
```

Para executar no Chrome:

```powershell
flutter run -d chrome
```

Para executar num emulador Android:

```powershell
flutter devices
flutter run -d <id-do-emulador>
```

Para executar num telemóvel Android ligado ao computador, é necessário utilizar o endereço IP local do computador em vez de `localhost` ou `10.0.2.2`.

Exemplo:

```powershell
flutter run -d <id-do-dispositivo> --dart-define=API_URL=http://192.168.1.67:3000
```

O endereço IP deve ser ajustado à rede local utilizada. O telemóvel e o computador têm de estar ligados à mesma rede Wi-Fi, e a firewall deve permitir a comunicação com o servidor.

### 7.5 Verificação do projeto

Para analisar o código:

```powershell
flutter analyze
```

Para executar os testes:

```powershell
flutter test
```

## 8. Estrutura do projeto Flutter

```text
lib/
├── main.dart
├── data/
│   ├── models.dart
│   └── dados_exemplo.dart
├── screens/
│   ├── home_shell.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── onboarding_screen.dart
│   ├── profile_screen.dart
│   ├── profile_edit_screen.dart
│   ├── find_players_screen.dart
│   ├── player_profile_screen.dart
│   ├── invites_screen.dart
│   ├── create_game_screen.dart
│   ├── games_screen.dart
│   ├── history_screen.dart
│   ├── map_screen.dart
│   ├── game_detail_screen.dart
│   └── checkin_screen.dart
├── services/
│   └── api.dart
├── theme/
├── utils/
└── widgets/
    ├── app_icons.dart
    ├── logo.dart
    └── bottom_nav.dart

test/
└── widget_test.dart
```

O ficheiro `lib/services/api.dart` centraliza a comunicação entre a aplicação Flutter e o backend.

## 9. Testes e validação

A validação deve contemplar a comunicação entre o frontend, a API e a base de dados.

Os principais cenários de teste incluem:

1. Criar uma conta e iniciar sessão;
2. Consultar e atualizar o perfil;
3. Consultar modalidades e níveis desportivos;
4. Pesquisar jogadores;
5. Criar um jogo;
6. Consultar jogos disponíveis;
7. Entrar num jogo;
8. Enviar, aceitar e recusar convites;
9. Consultar notificações;
10. Consultar o histórico de jogos;
11. Verificar o fluxo de check-in por QR Code;
12. Confirmar a persistência dos dados após fechar e voltar a abrir a aplicação.

Os resultados dos testes devem ser registados com o respetivo cenário, resultado esperado, resultado obtido e estado de aprovação.

## 10. Estado do desenvolvimento

O projeto encontra-se numa fase de protótipo funcional, com aplicação Flutter, backend Node.js/Express e base de dados MySQL integrados.

A execução em dispositivo Android físico requer a configuração do endereço IP local do computador para permitir a comunicação com a API.

As funcionalidades devem ser consideradas concluídas apenas após a respetiva validação integrada no dispositivo e confirmação da persistência dos dados.

## 11. Organização e controlo de versões

O código-fonte é mantido no GitHub:

https://github.com/tchaliuziel/WhoPlay-app

O Git é utilizado para controlar as alterações ao frontend, backend, scripts SQL e documentação técnica.

Ficheiros de configuração locais, credenciais, pastas `node_modules/`, `.dart_tool/` e artefactos de compilação não devem ser publicados no repositório.

---

**WhoPlay — Encontra. Marca. Joga.**
