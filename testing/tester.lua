local t = {
    tests = {
        fonts = 'testing.font_test'
    }
}

function t:run(test)
    print('trying to run tests')
    if self.tests[test] then
        __test:start(test)
        self.currentTest = require(self.tests[test])()
        __test:stop(test, 'tester environment first run complete, test persistence is: '..tostring(self.currentTest and "true" or "false"))
    end
end


function t:update(dt)
    if type(self.currentTest) == "table" and self.currentTest.update then
        self.currentTest:update(dt)
    end

end


function t:draw()
    if type(self.currentTest) == "table" and self.currentTest.draw then
        self.currentTest:draw()
    end
end


return t