-- the RNG system for gamecrash games
-- first iteration is just going to be some actions that establish a proper RNG seed

love.math.setRandomSeed(os.time())
love.math.random()
love.math.random()
love.math.random()
love.math.random()
