# VoxMateria — versão vertical Godot

FPS voxel original, com extração de matéria, criação composicional em português, física 3D, voz offline e ENet. Esta é a primeira versão funcional prevista na especificação; não representa a conclusão de todos os 25 capítulos.

## Baixar

No GitHub, abra **Actions → VoxMateria Godot offline - Windows → execução concluída → Artifacts → VoxMateria-Godot-Windows-offline**. Extraia todo o ZIP e execute VoxMateria.exe, mantendo a pasta voice ao lado. Windows 10/11, 64 bits.

A versão anterior WordForge, incluindo o APK Android, continua disponível no workflow Compilar jogo. O novo projeto Godot tem alvo Windows; o APK anterior não contém as novas mecânicas voxel/offline.

## Primeiro uso

O jogo inicia com **zero matéria**. Aponte para o chão ou uma parede, mantenha o clique no modo EXTRAÇÃO e colete blocos. Cada bloco rende 5 unidades. Os blocos saem da malha e da colisão; o buraco é utilizável.

Pressione T, escreva um pedido e confirme com Enter. O custo estimado aparece ao digitar. Segure V para falar; solte para finalizar. Um toque rápido em V alterna extração/equipamento.

Exemplos: um cubo; cinco cubos; um cubo gigante; um pato voador; três patos orbitando; um robô que me siga; um robô voador que lança bolas de tinta; uma torre que lança bolas; um cubo que lança pássaros; um pássaro que lança cubos; um lançador de três saídas que dispara cubos de gelatina; uma parede; um portal; um buraco negro; quero voar; quero pular mais alto; quero correr rápido; quero ficar invisível; um jetpack.

O servidor verifica matéria, limite e posição antes de fabricar. Quantidade máxima: cinco por pedido, 24 criações ativas. Objetos duram até dois minutos. Habilidades duram 35 segundos. Comandos desconhecidos são recusados com o conceito ausente, sem fingir sucesso.

## Voz realmente local

O backend usa Vosk e sounddevice em processo separado. Não usa API comercial. O pacote tenta incluir o modelo português oficial no build. Se a pasta models/vosk-model-small-pt-0.3 não existir, execute em PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\voice\instalar-modelo.ps1
```

Esse download só é necessário na instalação. Depois de instalado o modelo, captura, reconhecimento e interpretação funcionam sem internet. No menu Esc, selecione o microfone e use Iniciar / diagnosticar voz offline. É possível indicar outra pasta Vosk no campo de modelo.

O nível do microfone, a fala parcial e erros reais são mostrados. Áudio PCM fica em memória; não é gravado em arquivos nem enviado a terceiros. Apenas estado e texto reconhecido passam pelo diretório local de sessão. Há limite de 20 segundos, cancelamento por Esc, tratamento de silêncio e conversão para 16 kHz. A entrada por texto permanece utilizável sem microfone/modelo.

O reconhecimento depende do modelo, ruído e pronúncia. A interpretação é determinística e tem catálogo explícito; não promete compreender literalmente qualquer frase ou conceito. Não há IA generativa paga por trás.

## Controles

WASD move; mouse olha; Espaço pula; Shift corre; C agacha; clique usa/extrai; V curto alterna modo, V segurado captura fala; T abre texto; F5 alterna primeira/terceira pessoa; Esc abre menu e cancela fala. Habilidade de voo: Espaço sobe e Ctrl desce.

## Multiplayer

Criar sala abre servidor ENet UDP 26077, até quatro jogadores. Os demais entram pelo IP do anfitrião. Na LAN, permita o jogo na rede privada; pela internet, é necessária configuração apropriada de roteador/servidor e porta UDP acessível. Não há serviço público de matchmaking.

Somente o servidor interpreta pedidos, cobra matéria e cria entidades. Clientes enviam texto e entradas limitadas. Eventos confiáveis replicam criações e edições de blocos; snapshots interpolam movimento. Quem entra depois recebe as alterações do cenário e as entidades existentes. Voz é reconhecida localmente; não há chat de voz nesta versão.

## Arquitetura

Godot 4.6.3, GDScript; módulos de normalização, registro de conceitos, parser, grafo intermediário, custo, validação, fábrica e binding físico. O catálogo de aliases fica em data/concepts.json. Novos aliases para entidades existentes não exigem cenas novas. Novas espécies/comportamentos exigem implementação correspondente, não apenas alteração do nome.

O mapa Ilhas Suspensas usa dados voxel e chunks de 8³, malha só com faces expostas e colisor por chunk. Edições atualizam chunks locais, sem um nó por bloco. O colapso é uma regra local limitada de suporte, não análise estrutural completa.

Criaturas usam corpos rígidos e componentes de seguir, voar, orbitar, saltitar e girar. Há emissores com saídas visíveis, projéteis com colisão e ricochete limitado, campos de atração, portais em par e habilidades temporárias. O bot é básico: coleta, equipa e combate; não possui navegação avançada nem três dificuldades prontas.

## Desenvolvimento

Abra project.godot no Godot 4.6.3. Para voz em desenvolvimento, use Python 3.11 e instale voice/requirements.txt. Instale o modelo em models/. O export Windows inclui recognizer.exe construído pelo PyInstaller; a máquina do jogador não precisa de Python.

```sh
godot --headless --path godot --editor --import --quit
godot --headless --path godot --script res://tests/suite.gd
python godot/tests/network_smoke.py godot
```

Os caminhos desses comandos pressupõem execução na raiz do repositório. No editor, a pasta godot é a raiz do projeto.

## Estado e testes

- 57 verificações locais passaram: linguagem, acentos, plurais, combinações, emissor triplo, custos, limites, faces internas removidas, remoção de voxel, deltas de entrada tardia, colisão do jogador, extração por raio físico, recursos, criação e habilidades.
- O teste de rede executa processos Godot reais com ENet, criação autorizada, custo e entrada tardia. O resultado da compilação CI está na aba Actions e nos relatórios anexados.
- O workflow exporta o EXE e o executa em Windows em modo headless; também verifica os imports do backend de voz. Consulte o resultado efetivo da execução.
- Não foi validado microfone físico, precisão de fala em sotaques diferentes, renderização em uma GPU real do usuário ou desempenho na configuração de referência. Nenhum resultado de reconhecimento simulado é apresentado como teste de microfone.

## O que ainda falta da especificação completa

Dois mapas de expansão; greedy meshing; navegação dinâmica avançada; cordas; carregamento de objetos por criaturas; geração recursiva/multiplicação; todos os poderes e modificadores; animações e som com acabamento final; opções gráficas completas; chat de voz; testes de desempenho e exportação Android Godot com voz offline. A liberdade atual é combinatória dentro dos componentes documentados.

Não há arquivos proprietários de LAVOICE. Código e modelos procedurais são próprios; dependências e respectivas licenças estão em THIRD-PARTY.md.
