import 'dart:ui' as ui;

import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_tiled/flame_tiled.dart' as ft;
import 'package:flame_audio/flame_audio.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:mygame/components/Menu/flashcard/business/Flashcard.dart';
import 'package:mygame/components/Menu/flashcard/business/Deck.dart';
import 'package:mygame/vocab/screen/cardlevel/cardlevelscreen.dart';
import 'package:mygame/components/Menu/pausemenu.dart';
import 'package:provider/provider.dart';
import 'ui/health.dart';
import 'ui/experience.dart';
import 'ui/gold_hud.dart';
import 'components/tiledobject.dart';
import 'components/collisionmap.dart';
import 'components/enemy_wander.dart';
import 'enemy.dart';
import 'components/battle_scene.dart';
import 'player.dart';
import 'dialog/dialog_manager.dart';
import 'dialog/dialog_overlay.dart';
import 'components/npc.dart';
import 'components/coin.dart';
import 'ui/return_button.dart';
import 'ui/area_title.dart';
import 'package:mygame/components/Menu/mainmenu.dart';
import 'package:mygame/components/Menu/pausebutton.dart';
import 'components/Menu/flashcard/screen/decklist/deckwelcome.dart';

import 'audio/audio_manager.dart';
import 'ui/settings_overlay.dart';
import 'ui/shop_overlay.dart';
import 'state/inventory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlameAudio.audioCache.prefix = 'assets/';
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await AudioManager.instance.init();

  final deckModel = Deckmodel();
  await deckModel.fetchDecks();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Cardmodel()),
        ChangeNotifierProvider.value(value: deckModel),
        ChangeNotifierProvider.value(value: Inventory.instance),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'MyFont'),
        home: GameWidget(
          game: MyGame(),
          overlayBuilderMap: {
            DialogOverlay.id: (context, game) {
              final g = game as MyGame;
              return DialogOverlay(manager: g.dialogManager);
            },
            ReturnButton.id: (context, game) {
              final g = game as MyGame;
              return ReturnButton(actions: g.rightActions);
            },
            "MainMenu": (context, game) {
              return MainMenu(game: game as MyGame);
            },
            "PauseButton": (context, game) {
              return PauseButton(game: game as MyGame);
            },
            "PauseMenu": (context, game) {
              return PauseMenu(game: game as MyGame);
            },
            'Flashcards': (context, game) {
              final g = game as MyGame;
              return Material(
                color: Colors.black54,
                child: SafeArea(
                  child: Scaffold(
                    backgroundColor: Colors.white,
                    extendBodyBehindAppBar: true,
                    appBar: AppBar(
                      backgroundColor:
                          Colors.transparent, 
                      elevation: 0,
                      title: const Text('Flashcards'),
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          g.overlays.remove('Flashcards');
                          g.resumeEngine();
                        },
                      ),
                    ),
                    body: const DeckListScreen(),
                  ),
                ),
              );
            },
            'CardLevelScreen': (context, game) {
              return Cardlevelscreen(game: game as MyGame);
            },
            SettingsOverlay.id: (context, game) {
              return SettingsOverlay(audio: AudioManager.instance);
            },
            ShopOverlay.id: (context, game) {
              final g = game as MyGame;
              return ShopOverlay(
                onClose: () async {
                  g.overlays.remove(ShopOverlay.id);
                  await g.showAreaTitle('Cảm ơn bạn đã mua hàng');
                },
              );
            },
          },

          initialActiveOverlays: const ['PauseButton', 'MainMenu'],
        ),
      ),
    ),
  );
}

class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  BattleScene? _battleScene;
  bool _inBattle = false;
  Vector2? _savedJoystickPos;

  @override
  late World world;
  late Health heartsHud;
  late ExperienceBar expHud;
  late GoldHud goldHud;
  late ft.TiledComponent map;
  late Rect mapBounds;
  final PositionComponent hudRoot = PositionComponent(priority: 100000);
  late final CameraComponent gameCamera;

  late Player player;
  JoystickComponent? joystick;

  final DialogManager dialogManager = DialogManager();
  final ValueNotifier<List<RightAction>> rightActions =
      ValueNotifier<List<RightAction>>(<RightAction>[]);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    world = World();
    await add(world);

    map = await ft.TiledComponent.load(
      'map.tmx',
      Vector2.all(16),
      prefix: 'assets/maps/',
      priority: 0,
    );
    await world.add(map);

    await _initMapObjects('map.tmx');

    final collision = Collision(map: map, parent: world);
    await collision.loadLayer("collision");

    final mapW = map.tileMap.map.width * 16.0;
    final mapH = map.tileMap.map.height * 16.0;
    mapBounds = Rect.fromLTWH(0, 0, mapW, mapH);

    player = Player(position: Vector2(310, 138));
    await world.add(player);

    gameCamera = CameraComponent(world: world, hudComponents: []);
    await add(gameCamera);
    gameCamera.viewfinder.zoom = 2.5;
    gameCamera.follow(player, maxSpeed: 5000);
    gameCamera.setBounds(Rectangle.fromLTWH(0, 0, mapW, mapH));
    gameCamera.viewfinder.position = player.position;

    hudRoot.size = size;
    await gameCamera.viewport.add(hudRoot);

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 30,
        paint: Paint()..color = const Color.fromARGB(255, 200, 230, 255),
      ),
      background: CircleComponent(
        radius: 60,
        paint: Paint()..color = const Color.fromARGB(255, 253, 253, 253),
      ),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    await hudRoot.add(joystick!);
    player.joystick = joystick;

    await showAreaTitle('Overworld');

    dialogManager.onRequestOpenOverlay = () {
      overlays.add(DialogOverlay.id);
      _lockControls(true);
      // Keep settings button visible on top
      if (overlays.isActive(SettingsOverlay.id)) {
        overlays.remove(SettingsOverlay.id);
        overlays.add(SettingsOverlay.id);
      }
    };

    heartsHud = Health(
      maxHearts: 5,
      currentHearts: 5,
      fullHeartAsset: 'hp/heart.png',
      emptyHeartAsset: 'hp/empty_heart.png',
      heartSize: 32,
      spacing: 6,
      margin: const EdgeInsets.only(left: 8, top: 4),
    );
    await hudRoot.add(heartsHud);

    expHud = ExperienceBar(
      margin: const EdgeInsets.only(left: 8, top: 40),
      onLevelUp: (lv) async {
        await showAreaTitle('Level Up! Lv $lv');
      },
    );
    await hudRoot.add(expHud);

    goldHud = GoldHud(margin: const EdgeInsets.only(left: 8, top: 56));
    await hudRoot.add(goldHud);

    dialogManager.onRequestCloseOverlay = () {
      if (overlays.isActive(DialogOverlay.id)) {
        overlays.remove(DialogOverlay.id);
      }
      _lockControls(false);
    };

    if (!kIsWeb) {
      await AudioManager.instance.playBgm(
        'audio/bgm_overworld.mp3',
        volume: 0.4,
      );
    }
    overlays.add(SettingsOverlay.id);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    hudRoot.size = newSize;
  }

  Future<void> showAreaTitle(String text) async {
    await hudRoot.add(AreaTitle(text));
  }

  void _lockControls(bool lock) {
    final js = joystick;
    if (lock) {
      player.joystick = null;
      if (js != null && js.parent != null) js.removeFromParent();
    } else {
      if (js != null && js.parent == null) {
        hudRoot.add(js);
      }
      if (js != null) player.joystick = js;
    }
  }

  Future<void> _initMapObjects(String mapFile) async {
    if (mapFile == 'map.tmx') {
      final loader = TiledObjectLoader(map, world);
      await loader.loadLayer("house");

      final wisemanNPC = Npc(
        position: Vector2(52, 90),
        manager: dialogManager,
        interactLines: const ['Winter is comming!', 'Dont go to the north.'],
        interactOrderMode: InteractOrderMode.alwaysFromStart,
        interactPrompt: 'You cant fight with that body, train with me!',
        interactChoices: [
          DialogueChoice(
            'Start Card Training',
            onSelected: () {
              overlays.add('CardLevelScreen');
            },
          ),
          DialogueChoice('Not Right Now', onSelected: dialogManager.close),
        ],
        idleLines: const [
          'You know nothing, Jon Snow',
          'Why Would A Girl See Blood And Collapse?',
        ],
        enableIdleChatter: true,
        spriteAsset: 'chihiro.png',
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(64, 64),
        size: Vector2(40, 40),
        avatarAsset: 'assets/images/Eleonore_avatar.png',
        avatarDisplaySize: const Size(162, 162),
        interactRadius: 28,
        zPriority: 20,
      );
      await world.add(wisemanNPC);

      final npc1 = Npc(
        position: Vector2(660, 112),
        manager: dialogManager,
        interactLines: ['Xin chào!', 'Bạn cần gì?'],
        interactOrderMode: InteractOrderMode.alwaysFromStart,
        interactPrompt: 'Bạn muốn làm gì?',
        interactChoices: [
          DialogueChoice(
            'Vào thư viện',
            onSelected: () async {
              dialogManager.close();
              await loadMap('houseinterior.tmx', spawn: Vector2(182, 172));
            },
          ),
          DialogueChoice('Tạm biệt', onSelected: dialogManager.close),
        ],
        idleLines: ['Hmm...', 'Nghe nói phía bắc có kho báu.'],
        enableIdleChatter: true,
        spriteAsset: 'Eleonore.png',
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(64, 64),
        size: Vector2(40, 40),
        avatarAsset: 'assets/images/Eleonore_avatar.png',
        avatarDisplaySize: const Size(162, 162),
        interactRadius: 28,
        zPriority: 20,
      );
      await world.add(npc1);

      final npc2 = Npc(
        position: Vector2(876, 560),
        manager: dialogManager,
        interactLines: ['Xin chào!', 'Bạn cần gì?'],
        interactOrderMode: InteractOrderMode.alwaysFromStart,
        interactPrompt: 'Xin chào!, Bạn cần gì?',
        interactChoices: [
          DialogueChoice(
            'Vào đảo undead',
            onSelected: () async {
              dialogManager.close();
              await loadMap('dungeon.tmx', spawn: Vector2(1260, 650));
            },
          ),
          DialogueChoice('Tạm biệt', onSelected: dialogManager.close),
        ],
        idleLines: ['Hmm...', 'Nghe nói phía bắc có kho báu.'],
        enableIdleChatter: true,
        spriteAsset: 'Joanna.png',
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(64, 64),
        size: Vector2(40, 40),
        avatarAsset: 'assets/images/Joanna_avatar.png',
        avatarDisplaySize: const Size(162, 162),
        interactRadius: 28,
        zPriority: 20,
      );
      await world.add(npc2);

      final shopNpc = Npc(
        position: Vector2(312, 342),
        manager: dialogManager,
        interactLines: const ['Xin chào!', 'Bạn muốn mua gì không?'],
        interactOrderMode: InteractOrderMode.alwaysFromStart,
        interactPrompt: 'Chọn hành động:',
        interactChoices: [
          DialogueChoice(
            'Mua vật phẩm',
            onSelected: () async {
              dialogManager.close();
              overlays.add(ShopOverlay.id);
            },
          ),
          DialogueChoice('Tạm biệt', onSelected: dialogManager.close),
        ],
        idleLines: const ['Giá rẻ như bèo!', 'Đồ mới về đây!'],
        enableIdleChatter: true,
        spriteAsset: 'Eleonore.png',
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(64, 64),
        size: Vector2(40, 40),
        avatarAsset: 'assets/images/Eleonore_avatar.png',
        avatarDisplaySize: const Size(162, 162),
        interactRadius: 28,
        zPriority: 20,
      );
      await world.add(shopNpc);

      await world.add(
        EnemyWander(
          patrolRect: ui.Rect.fromLTWH(700, 500, 160, 120),
          spritePath: 'Joanna.png',
          speed: 35,
          triggerRadius: 40,
          enemyType: EnemyType.normal,
        ),
      );

      await world.add(
        EnemyWander(
          patrolRect: ui.Rect.fromLTWH(800, 600, 160, 120),
          spritePath: 'Joanna.png',
          speed: 35,
          triggerRadius: 40,
          enemyType: EnemyType.strong,
        ),
      );

      await world.add(
        EnemyWander(
          patrolRect: ui.Rect.fromLTWH(900, 700, 160, 120),
          spritePath: 'Joanna.png',
          speed: 35,
          triggerRadius: 40,
          enemyType: EnemyType.miniboss,
        ),
      );
      await world.add(
        EnemyWander(
          patrolRect: ui.Rect.fromLTWH(900, 700, 160, 120),
          spritePath: 'Joanna.png',
          speed: 35,
          triggerRadius: 40,
          enemyType: EnemyType.miniboss,
        ),
      );

      await world.add(
        EnemyWander(
          patrolRect: ui.Rect.fromLTWH(700, 500, 160, 120),
          spritePath: 'Joanna.png',
          speed: 35,
          triggerRadius: 40,
          enemyType: EnemyType.boss,
        ),
      );
    } else if (mapFile == 'dungeon.tmx') {
      await world.add(
        Enemy(
          patrolRect: ui.Rect.fromLTWH(970, 465, 80, 60),
          speed: 30,
          triggerRadius: 48,
          enemyType: EnemyType.normal,
        ),
      );

      await world.add(
        Enemy(
          patrolRect: ui.Rect.fromLTWH(1035, 300, 80, 60),
          speed: 28,
          triggerRadius: 48,
          enemyType: EnemyType.strong,
        ),
      );

      await world.add(
        Enemy(
          patrolRect: ui.Rect.fromLTWH(230, 530, 80, 60),
          speed: 32,
          triggerRadius: 48,
          enemyType: EnemyType.miniboss,
        ),
      );

      await world.add(
        Enemy(
          patrolRect: ui.Rect.fromLTWH(265, 300, 80, 60),
          speed: 20,
          triggerRadius: 60,
          enemyType: EnemyType.boss,
        ),
      );
      await world.add(
        Enemy(
          patrolRect: ui.Rect.fromLTWH(500, 375, 80, 60),
          speed: 30,
          triggerRadius: 48,
          enemyType: EnemyType.normal,
        ),
      );

      await world.add(
        Enemy(
          patrolRect: ui.Rect.fromLTWH(745, 485, 80, 60),
          speed: 28,
          triggerRadius: 48,
          enemyType: EnemyType.strong,
        ),
      );
    }
  }

  Future<void> enterBattle({required EnemyType enemyType}) async {
    if (_inBattle) return;
    _inBattle = true;

    if (overlays.isActive(SettingsOverlay.id)) {
      overlays.remove(SettingsOverlay.id);
    }

    world.removeFromParent();
    gameCamera.removeFromParent();

    if (player.joystick != null) {
      _savedJoystickPos = joystick?.position.clone();
      player.joystick = null;
      if (joystick != null) {
        joystick!.position = Vector2(-10000, -10000);
      }
    }

    heartsHud.removeFromParent();

    // pause nhạc nền khi vào battle
    await AudioManager.instance.pauseBgm();

    _battleScene = BattleScene(
      onEnd: (result) => exitBattle(result),
      enemyType: enemyType,
    );
    await add(_battleScene!);
    _battleScene!.heroHealth.setCurrent(heartsHud.currentHearts);
  }

  void exitBattle(BattleResult result) {
    final remainHearts =
        _battleScene?.heroHealth.currentHearts ?? heartsHud.currentHearts;

    _battleScene?.removeFromParent();
    _battleScene = null;
    _inBattle = false;

    add(world);
    add(gameCamera);

    hudRoot.add(heartsHud);
    heartsHud.setCurrent(remainHearts);

    if (result.outcome == 'win') {
      if (result.xpGained > 0) { expHud.addXp(result.xpGained); }


      // if (result.goldGained > 0) { goldHud.addGold(result.goldGained); }


      if (result.goldGained > 0) {
        goldHud.addGold(result.goldGained);
      }
    }

    if (joystick != null) {
      if (_savedJoystickPos != null) {
        joystick!.position = _savedJoystickPos!;
      }
      player.joystick = joystick;
    }

    if (result.outcome == 'lose') {
      heartsHud.refill();
      player.position = Vector2(1255, 655);
    }

    // continue nhạc nền khi thoát battle
    AudioManager.instance.resumeBgm();

    // Restore settings overlay after battle
    if (!overlays.isActive(SettingsOverlay.id)) {
      overlays.add(SettingsOverlay.id);
    }
  }

  Future<void> loadMap(
    String mapFile, {
    required Vector2 spawn,
    Vector2? spawnTile,
    double tileSize = 16,
  }) async {
    if (world.parent != null) world.removeFromParent();

    final newWorld = World();
    await add(newWorld);
    world = newWorld;

    // Set scale for dungeon.tmx
    if (mapFile == 'dungeon.tmx') {
      map = await ft.TiledComponent.load(
        mapFile,
        Vector2.all(tileSize),
        prefix: 'assets/maps/',
        priority: 0,
      );
      map.scale = Vector2.all(0.6);
      await world.add(map);
    } else {
      map = await ft.TiledComponent.load(
        mapFile,
        Vector2.all(tileSize),
        prefix: 'assets/maps/',
        priority: 0,
      );
      await world.add(map);
    }

    await _initMapObjects(mapFile);

    final collision = Collision(map: map, parent: world);
    await collision.loadLayer("collision");

    final mapW = map.tileMap.map.width * tileSize;
    final mapH = map.tileMap.map.height * tileSize;
    mapBounds = Rect.fromLTWH(0, 0, mapW, mapH);

    Vector2 finalSpawn;
    if (spawnTile != null) {
      finalSpawn = Vector2(
        (spawnTile.x + 0.5) * tileSize,
        (spawnTile.y + 0.5) * tileSize,
      );
    } else {
      finalSpawn = spawn;
    }

    finalSpawn = Vector2(
      finalSpawn.x.clamp(0, mapW - player.size.x).toDouble(),
      finalSpawn.y.clamp(0, mapH - player.size.y).toDouble(),
    );

    if (player.parent != null) player.removeFromParent();
    player = Player(position: finalSpawn);
    await world.add(player);

    gameCamera.world = world;
    gameCamera.follow(player, maxSpeed: 5000);
    gameCamera.setBounds(Rectangle.fromLTWH(0, 0, mapW, mapH));
    gameCamera.viewfinder.position = player.position;

    if (joystick != null && joystick!.parent == null) {
      await hudRoot.add(joystick!);
    }
    player.joystick = joystick;

    await showAreaTitle(
      mapFile == 'houseinterior.tmx'
          ? 'Library'
          : mapFile == 'dungeon.tmx'
          ? 'Welcome to Undead Island'
          : 'Overworld',
    );

    if (mapFile == 'houseinterior.tmx') {
      await world.add(
        Coin(
          position: finalSpawn.clone(),
          interactRadius: 140,
          onCollected: () async {
            await loadMap('map.tmx', spawn: Vector2(657, 135));
          },
        ),
      );
      await world.add(
        Coin(
          position: Vector2(334, 329),
          interactRadius: 60,
          persistent: true,
          onCollected: () {
            pauseEngine();
            overlays.add('Flashcards');
          },
        ),
      );
    } else if (mapFile == 'dungeon.tmx') {
      await world.add(
        Coin(
          position: finalSpawn.clone(),
          interactRadius: 140,
          onCollected: () async {
            await loadMap('map.tmx', spawn: Vector2(955, 672));
          },
        ),
      );
    } else if (mapFile == 'map.tmx') {
      await world.add(
        Coin(
          position: Vector2(362, 280),
          interactRadius: 80,
          persistent: true,
          onCollected: () async {
            await loadMap('shop.tmx', spawn: Vector2(120, 120));
          },
        ),
      );
    } else if (mapFile == 'shop.tmx') {
      await world.add(
        Coin(
          position: Vector2(120, 120),
          interactRadius: 80,
          persistent: true,
          onCollected: () async {
            await loadMap('map.tmx', spawn: Vector2(362, 280));
          },
        ),
      );
    }
  }
}
