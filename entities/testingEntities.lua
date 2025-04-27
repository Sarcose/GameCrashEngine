local entities = {
    [1] = {
        name = "Joe",
        pos = {x=0,y=0},
        dims = {w=10,h=10},
        color = {1,0,1},
        phrase = "I'm a control!",
        mass = 150,
        hairColor = "brown",
        timer = 2,
        say = "Uninitiated!!!"
    },
    [2] = {
        name = "Shape",
        pos = {x=30,y=30},
        dims = {w=10,h=10},
        color = {0,0,1},
        shape = "rectangle",
        phrase = "I'm a shape person!!",
        mass = 150,
        hairColor = "green",
        timer = 2,
        say = "Uninitiated!!!"
    },
    [3] = {
        name = "Sprite",
        pos = {x=50,y=60},
        dims = {w=10,h=10},
        color = {0,0,1},
        phrase = "I'm a sprite person!!",
        sprite = love.graphics.newImage('assets/player.png'),
        mass = 150,
        hairColor = "red",
        timer = 2,
        say = "Uninitiated!!!"
    },
    [4] = {
        name = "Both",
        pos = {x=100,y=60},
        dims = {w=10,h=10},
        color = {0,1,0},
        shape = "rectangle",
        phrase = "I'm a sprite AND shape person!!",
        sprite = love.graphics.newImage('assets/enemy.png'),
        mass = 150,
        hairColor = "red",
        timer = 2,
        say = "Uninitiated!!!"
    },
}

return entities