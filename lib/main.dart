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
import 'package:mygame/components/Menu/pausemenu.dart';
import 'ui/health.dart';
import 'ui/experience.dart';
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
// duplicate imports removed
import 'package:mygame/components/Menu/mainmenu.dart';
import 'package:mygame/components/Menu/pausebutton.dart';
import 'package:provider/provider.dart';
import 'components/Menu/flashcard/business/Deck.dart';
import 'components/Menu/flashcard/business/Flashcard.dart';
import 'components/Menu/flashcard/screen/decklist/deckwelcome.dart';

import 'audio/audio_manager.dart';
import 'ui/settings_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlameAudio.audioCache.prefix = 'assets/';
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize audio (safe on web), but don't autoplay until user gesture
  await AudioManager.instance.init();

  runApp(
    MaterialApp(
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
          // Overlay to host Flashcards screens
          'Flashcards': (context, game) {
            final g = game as MyGame;
            return Material(
              color: Colors.black54,
              child: SafeArea(
                child: Scaffold(
                  backgroundColor: Colors.white,
                  appBar: AppBar(
                    title: const Text('Flashcards'),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        g.overlays.remove('Flashcards');
                        g.resumeEngine();
                      },
                    ),
                  ),
                  body: MultiProvider(
                    providers: [
                      ChangeNotifierProvider<Deckmodel>(
                        create: (_) => Deckmodel()..fetchDecks(),
                      ),
                      ChangeNotifierProvider<Cardmodel>(
                        create: (_) => Cardmodel(),
                      ),
                    ],
                    child: const DeckListScreen(),
                  ),
                ),
              ),
            );
          },
          SettingsOverlay.id: (context, game) {
            return SettingsOverlay(audio: AudioManager.instance);
          },
        },
        initialActiveOverlays: const ['PauseButton', 'MainMenu'],
      ),
    ),
  );
}

class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  BattleScene? _battleScene;
  bool _inBattle = false;
  Vector2? _savedJoystickPos;

  late World world;
  late Health heartsHud;
  late ExperienceBar expHud;
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

    dialogManager.onRequestCloseOverlay = () {
      if (overlays.isActive(DialogOverlay.id)) {
        overlays.remove(DialogOverlay.id);
      }
      _lockControls(false);
    };

    // On web, defer autoplay until user interaction (MainMenu button)
    if (!kIsWeb) {
      await AudioManager.instance.playBgm(
        'audio/bgm_overworld.mp3',
        volume: 0.4,
      );
    }

    // Ensure settings button is visible by default
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
              await loadMap('Undead_land.tmx', spawn: Vector2(354, 102));
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

      // Create NPCs that walk around the map
      await world.add(
        Enemy(
          patrolRect: ui.Rect.fromLTWH(300, 550, 160, 120),
          speed: 25,
          triggerRadius: 40,
          enemyType: EnemyType.normal,
        ),
      );

      await world.add(
        Enemy(
          patrolRect: ui.Rect.fromLTWH(700, 500, 160, 120),
          speed: 30,
          triggerRadius: 40,
          enemyType: EnemyType.strong,
        ),
      );

      await world.add(
        Enemy(
          patrolRect: ui.Rect.fromLTWH(800, 600, 160, 120),
          speed: 35,
          triggerRadius: 40,
          enemyType: EnemyType.miniboss,
        ),
      );

      await world.add(
        Enemy(
          patrolRect: ui.Rect.fromLTWH(700, 500, 160, 120),
          speed: 20,
          triggerRadius: 40,
          enemyType: EnemyType.boss,
        ),
      );
    }
  }

  Future<void> enterBattle({required EnemyType enemyType}) async {
    if (_inBattle) return;
    _inBattle = true;

    // Hide settings overlay during battle
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

    // Cộng XP nếu thắng
    if (result.outcome == 'win' && result.xpGained > 0) {
      expHud.addXp(result.xpGained);
    }

    if (joystick != null) {
      if (_savedJoystickPos != null) {
        joystick!.position = _savedJoystickPos!;
      }
      player.joystick = joystick;
    }

    if (result.outcome == 'lose') {
      heartsHud.refill();
      player.position = Vector2(310, 138);
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

    map = await ft.TiledComponent.load(
      mapFile,
      Vector2.all(tileSize),
      prefix: 'assets/maps/',
      priority: 0,
    );
    await world.add(map);

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
          : mapFile == 'Undead_land.tmx'
          ? 'Welcome to Undead Island'
          : 'Overworld',
    );

    if (mapFile == 'houseinterior.tmx') {
      await world.add(
        Coin(
          position: finalSpawn.clone(),
          interactRadius: 140,
          onCollected: () async {
            await loadMap('map.tmx', spawn: Vector2(657, 133));
          },
        ),
      );
      // Flashcards event coin at fixed position (334, 329)
      await world.add(
        Coin(
          position: Vector2(334, 329),
          interactRadius: 60,
          persistent: true,
          onCollected: () {
            // Pause game and open flashcards overlay
            pauseEngine();
            overlays.add('Flashcards');
          },
        ),
      );
    } else if (mapFile == 'Undead_land.tmx') {
      await world.add(
        Coin(
          position: finalSpawn.clone(),
          interactRadius: 140,
          onCollected: () async {
            await loadMap('map.tmx', spawn: Vector2(955, 672));
          },
        ),
      );
    }
  }
}
