Basic usage plan:\
    - Copy Engine as new project\
    - #TODO: To make changes to physics *calculations and properties* see \
    - #TODO: To design a game without changing any of the basic engine start in /data/\
        - #TODO: data.brain already has options for human controllers vs. ai. Use Classes.Controller:extend() or Classes.AI:extend for a new prototype, otherwise use new\(properties) to define an instance
        - #TODO: data.entity has 'recipes' divided into subclasses for the following:\
            - #TODO: data.entity.actor; fully fleshed out entities, capable of anything, including attaching Parts. The Part system is limited to Actor for now.\
                - #TODO: data.entity.actor.part is the part system, constructing the actor with modularity. The base actor will be in many cases a simple "base" from which to build using parts.\
            - #TODO: data.entity.item; simplified entity that is specialized in applying a new or changed component to an entity upon their interaction with it. Inventory items or equipment.\
            - #TODO: data.entity.mechanism; like an item but specialized in triggering the game (the whole game, the world, the map, or entities as such) upon some condition. The basic scripting component\
                - #TODO: data.entity.mechanism:scene() begins the creation of a complex "mini-movie" (cutscene) where all designated and even arbitrary actors are taken control of and made to behave in scripted ways.\
            - #TODO: data.entity.terrain; recipes for entities which are intended to remain relatively unchanged or static. In Slick, can consist of composite shapes and a single or compound image for non-uniform "hand drawn" terrain\
        - #TODO: data.game is where "game modes" are defined. (See Gameplay entry point)\
        - #TODO: data.input is the input handling instance. Input() defines a basic set of control interfaces using baton, and someInput:register(buttons) defines specific buttons.\
        - #TODO: data.overlay is where menus, dialogue boxes, and HUDs (and anything else like this) are created. overlays access specific "GUI-style" display systems that other classes don't.\
        - #TODO: data.space is this engine's unique recursive-spatial-container system, allowing for maps inside maps that may recursively reference one another, layer on top of one another, or exist within a pseudo-3D space. The Space structure is what defines the 2.5D nature of the GameCrash Engine.\
        
        
        
Gameplay entry point:
    
    
                    |-------Input--->Brain--------                                               _________________________
                    |                             |                                             |  All of this data       |
                    |                           Entities-----------------------------           |  is arranged into a     |
                    |                           |       \           |                 \         |  collected document*    |  <---The game mode data structure is the same but the folder
    Game (mode)-----|-----------Space------"Universe"-->"World"-->"Level/Sector"-->"Room/Map"  <|  which is kept under    |             structure of the game itself is up to the designer.
                    |                      /                                                    |  game.modes.[gamename]  |
                    |-------Overlay-------/                                                     |_________________________|



Controller:\
    - #TODO: baton\

Physics:\
    - #TODO: bump (later Slick). The engine must be able to get a test game running.   <---a physics "world" is created in *each Space container* but only updated when those spaces are *active*\
    - #TODO: tiny-ecs will access bump (and later slick) functions and world calls.\
    - #TODO: flux will be used for physics easing\

Rendering:\
    - #TODO: handrolled texture rendering, to allow for live-drawing, cacheing, and rotating.\
    - #TODO: handrolled spritesheets\
    - #TODO: overlay system\
    - #TODO: push for scaling\
    - #TODO: sysl-text for text rendering\
    - #TODO: flux will be used for GUI easing\

Instantiation:\
    - classic.lua, implemented\
    - tiny.lua, for running systems                                        <--- an ecs "world" is created in *each Space container* but only updated when those spaces are *active*\

Randomization:\
    - #TODO: rng.lua, which will be built for instantiating and offering simultaneous RNG systems for handling discretely deterministic systems vs "true" pseudorandomness\


Miscellaneous/Utility:\
    - batteries,\
    - _g^crash.lua #TODO: improvements to this\
    - _g^crash_batteries.lua (addon that uses batteries specific functions)\

Debugging:\
    - debugcandy.lua\
    - debugcandy_hinting.lua\
    - quicktimer.lua\


