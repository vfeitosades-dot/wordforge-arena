# Polimento: modelos, animação e interface

O ZIP FPS_POLIMENTO_MODELOS_ANIMACOES_UI.zip foi utilizado como referência de direção e critérios de revisão. A entrega é uma melhoria concreta do protótipo solo existente, não a conclusão integral de todas as metas do documento.

## Auditoria antes da alteração

Os operadores anteriores eram androides de peças retangulares. Tiro e recarga substituíam a animação do corpo inteiro. A arma vista nos bots reutilizava o modelo com braços de primeira pessoa. Havia centenas de meshes separados e coordenadas fixas no HUD. Volume e sombras não eram restaurados corretamente. Reaparecimentos agendados podiam perder-se durante a pausa ou alcançar outra partida.

## Alterações entregues

- Quatro humanos estilizados: Serein, Rook, Vesper e Lumen. Face, cabelo, roupa, luvas com dedos, cotovelos, joelhos, botas e acessórios por papel. Lumen recebe sensor, rádio, antena e habilidade de rastreio de cinco segundos.
- Esqueleto com clavículas, braços, antebraços, mãos, dedos, coxas, panturrilhas e pés. Pesos preservados ao agrupar malhas por material.
- Pose de mira com empunhadura articulada, recarga e disparo sobre locomoção direcional. AnimationTree filtra o tronco e mantém pernas em movimento. Queda reproduzida antes da remoção do bot. Clipes de agachamento e reação são recursos autorais disponíveis, sem sistema de agachamento tático dos bots implementado.
- KestrelWorld, WispWorld e LongbowWorld excluem mãos e mangas do viewmodel. Bots usam KestrelWorld em BoneAttachment3D; o teste confirma a ligação à mão. As armas de primeira pessoa existentes são preservadas.
- Menu, minimapa, mira, HUD e loja posicionados pela área disponível. Ajustes persistentes de sensibilidade, FOV, volume, sombras, lado da arma, movimento reduzido e cor da mira. Restauração de padrões, feed de eliminação e luz de apresentação do operador.
- Reaparecimento usa tempo da partida: congela durante pausa e é descartado ao iniciar outra partida.
- Fontes Blender e recursos comprimidos, reconstruídos com SHA-256 antes da importação. A compactação preserva exatamente os bytes dos GLBs, sem perda visual.

## Validação funcional

Godot 4.6.3 e Blender 4.3.2. A suíte local concluiu 1.268 verificações com zero falhas. Inclui importação dos sete recursos animados, dez recursos GLB no total, bone chains, tracks e movimento real de bone, árvore de animação, movimento das pernas durante recarga, modelo externo sem braços de primeira pessoa, quatro arenas e navegação, munição, habilidades, economia, objetivo, pausa, configurações e reinício de partida.

Capturas reais de menu, configurações e partida foram feitas com Godot/OpenGL em llvmpipe. As quatro janelas 1280×720, 1366×768, 1920×1080 e 2560×1080 foram verificadas: o painel de ajustes permaneceu dentro da área visível. O Godot mantém área lógica 1280×720 em 16:9 e expande a largura em ultrawide. Medidas em ui-matrix.json. Isso não substitui teste em todos os monitores ou dispositivos.

A compilação Windows restaura recursos, importa, executa a suíte, exporta um EXE com PCK embutido e abre o EXE para um smoke test. O resultado final efetivo é o log da execução do GitHub Actions. A suíte não simula uma partida humana completa nem testa alto-falantes ou mouse físico.

## Medição antes e depois

Mesmo ambiente, resolução 1280×720, estande com cinco bots, seed 444 e 180 frames após aquecimento. A partida é pausada para manter posição e as animações continuam. Engine.max_fps=0. Renderer: **OpenGL llvmpipe por software**, sem GPU dedicada. O script de medição é performance_capture.gd; saídas completas em performance-before.json e performance-after.json.

| Medida | Antes | Depois |
|---|---:|---:|
| Chamadas de desenho | 1.519 | 858 |
| Primitivas reportadas | 105.732 | 103.828 |
| FPS médio | 8,07 | 7,51 |
| 1% baixo, estimativa com 180 frames | 6,21 | 3,32 |
| Memória estática reportada | 48,5 MB | 49,9 MB |
| Memória de vídeo reportada | 22,4 MB | 24,4 MB |

As chamadas diminuíram cerca de 43,5%, mas **não foi demonstrado aumento de FPS**. O resultado por software ficou mais lento e variável; o rig mais completo e o blend têm custo. Não há alegação de 60 FPS, orçamento de VRAM validado em GPU real ou comparabilidade com hardware comercial. Uma avaliação prolongada em GPU dedicada continua pendente.

## Pendências explícitas

Não há multiplayer 5v5, Android neste FPS, criação universal por voz, matchmaking, oito classes de arma, seis heróis, IK completo, retargeting, mocap, escultura humana de alta fidelidade ou sistema avançado de cobertura em equipe. Nenhum desses itens é apresentado como concluído. Mapas e áudio continuam simples. A suíte não garante ausência de bugs.

operators.jpg é um render do arquivo Blender. menu.png, game.png e settings.png são capturas do jogo. Nenhuma é uma imagem conceitual gerada para simular uma implementação.
