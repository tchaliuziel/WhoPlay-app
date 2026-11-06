# WhoPlay

**Encontra. Marca. Joga.**

Projeto Multidisciplinar — Desenvolvimento de uma aplicação móvel em Flutter.

## Grupo 6

| Nome | Número |
| --- | --- |
| Cristiano Cordeiro | 20251285 |
| Hélio José | 20250953 |
| Sebastião Cardoso | 20251225 |
| Tchali Tchalimba | 20252440 |

Repositório: https://github.com/tchaliuziel/WhoPlay-app

## Tema

O WhoPlay é uma aplicação que liga pessoas para praticar desporto (padel, ténis,
futebol, BJJ e outras modalidades). Com base na localização, no nível, na
disponibilidade e no objetivo de cada utilizador, a aplicação mostra os jogadores
mais compatíveis e os jogos com vagas perto de si.

## Ecrãs disponíveis

A app tem os 10 ecrãs dos mockups. Abre no **Login**; depois de entrar, a barra
inferior tem 5 entradas: Jogadores, Mapa, **+** (Criar jogo), Convites e Perfil.

| Nº | Ecrã | Como se chega |
| --- | --- | --- |
| 01 | Login | Ecrã inicial e depois de "Terminar sessão" |
| 02 | Onboarding (desportos) | Login → "Criar conta" → preencher e criar |
| 03 | Perfil | Separador Perfil |
| 04 | Encontrar jogadores | Separador Jogadores |
| 05 | Perfil do jogador | Jogadores → "Ver perfil" |
| 06 | Convites e avisos | Separador Convites (ou depois de enviar um convite) |
| 07 | Criar jogo | Botão verde **+** da barra inferior |
| 08 | Mapa | Separador Mapa |
| 09 | Detalhe do jogo | Mapa → "Ver jogo", ou depois de criar um jogo |
| 10 | Check-in por QR Code | Detalhe do jogo → "Entrar no jogo" / "Ver o meu QR Code" |

O ecrã "Criar conta" (registo) não está nos mockups e segue o estilo do "Criar jogo".

## Instruções de execução

Requisitos: Flutter SDK 3.22 ou mais recente (testado com o Flutter 3.47 / Dart 3.13)
e ligação à internet na primeira execução (as fontes Bricolage Grotesque e DM Sans
são descarregadas pelo pacote `google_fonts`).

Na pasta do projeto:

```bash
flutter pub get
flutter run -d chrome
```

Para correr num emulador Android ou num telemóvel ligado ao PC:

```bash
flutter devices
flutter run -d <id-do-dispositivo>
```

Para verificar o código:

```bash
flutter analyze
flutter test
```

## API do login (`api_login/`)

O login, o registo, os desportos do onboarding e o perfil (nome, email, desportos,
horários) são guardados a sério no MySQL do XAMPP, através da API em `api_login/`
(Node.js + Express, base de dados `whoplay_login`).

1. Ligar o MySQL no XAMPP.
2. Só da primeira vez: importar `api_login/schema.sql` no phpMyAdmin (cria a base de
   dados `whoplay_login` e as tabelas).
3. Só da primeira vez: instalar as dependências da API (`node_modules` não vai para o Git):

```bash
cd api_login
npm install
```

4. Arrancar a API (fica em `http://localhost:3000`):

```bash
cd api_login
npm start
```

Cada pessoa tem a sua própria base de dados no seu XAMPP: as contas criadas num PC não
existem nos outros. Na primeira vez, cria uma conta em "Criar conta".

5. Correr a app: `flutter pub get` e depois `flutter run -d chrome`.

## Funcionalidades simuladas

Tudo o resto ainda funciona **sem servidor**: em `lib/services/api.dart` os jogadores,
jogos, convites e avisos são guardados em memória. Por isso:

- **Dados de exemplo:** os jogadores, o jogo, os convites e os avisos vêm de
  `lib/data/dados_exemplo.dart` (os mesmos do `database/seed.sql`).
- **Ações que funcionam (em memória):** enviar convites, aceitar/recusar convites,
  criar um jogo, entrar num jogo e ver o QR Code de check-in. Ao fechar ou recarregar
  a app volta tudo ao início.
- **Perfil:** localidade, raio, objetivo e avaliação ainda não estão na base de dados
  e mostram os valores de exemplo.
- **Filtros sem ação:** as pílulas "Padel", "Ténis", "Até 5 km", "Hoje", "Raio 5 km"
  e "Jogos e jogadores" não filtram a lista.
- **Mapa ilustrativo:** o mapa é um desenho fixo (SVG), não usa o GPS.
- **Ainda por fazer:** "Editar" no Perfil, "Esqueci-me da palavra-passe" e
  "Guardar QR Code" só mostram uma mensagem.

O backend completo (`backend/`, base de dados `whoplay`) ainda não está ligado; a versão
da app para ele está em `arquivo/versao-api/lib/services/api.dart`.

## Estrutura do código

```text
lib/
├── main.dart                    arranque da aplicação
├── data/
│   ├── models.dart              classes de dados (Jogador, Jogo, Perfil…)
│   └── dados_exemplo.dart       dados fixos mostrados nos ecrãs
├── screens/
│   ├── home_shell.dart          barra inferior e troca de separadores
│   ├── login_screen.dart        01 Login
│   ├── register_screen.dart     Criar conta
│   ├── onboarding_screen.dart   02 Onboarding
│   ├── profile_screen.dart      03 Perfil
│   ├── find_players_screen.dart 04 Encontrar jogadores
│   ├── player_profile_screen.dart 05 Perfil do jogador
│   ├── invites_screen.dart      06 Convites e avisos
│   ├── create_game_screen.dart  07 Criar jogo
│   ├── map_screen.dart          08 Mapa
│   ├── game_detail_screen.dart  09 Detalhe do jogo
│   └── checkin_screen.dart      10 Check-in por QR Code
├── services/api.dart            login/perfil na api_login; resto em memória
├── theme/                       cores e tipografia
├── utils/formatos.dart          datas, distâncias e preços em pt-PT
└── widgets/                     componentes reutilizáveis (botões, cartões, ícones…)
test/widget_test.dart            testes unitários
```

Os ícones e o mapa são desenhados em SVG dentro do código (`lib/widgets/app_icons.dart`,
`lib/widgets/logo.dart`, `lib/screens/map_screen.dart`), por isso o projeto não tem
pasta de imagens.
