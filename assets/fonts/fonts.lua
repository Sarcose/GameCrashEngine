local dpi = love.graphics.getDPIScale() * 3 --#TODO: is this still needed?
local hinting = 'mono'
local function addFont(namespace, name,file,l,n,m,s,xs,newhinting,newdpi)
    if type(l) == 'string' then
        newhinting = l
        newdpi = n
        l = nil
        n = nil
    elseif type(n) == 'string' then
        newhinting = n
        newdpi = m or dpi
        n = nil
        m = nil
    elseif type(m) == 'string' then
        newhinting = m
        newdpi = s or dpi
        m = nil
        s = nil
    elseif type(s) == 'string' then
        newhinting = s
        newdpi = xs or dpi
        s = nil
        xs = nil
    elseif type(xs) == 'string' then
        newhinting = xs
        xs = nil
    end
    l = l or 80
    n = n or 64
    m = m or 48
    s = s or 32
    xs = xs or 16
    newhinting = newhinting or hinting
    newdpi = newdpi or dpi

    local fontmeta = {name = name}
    local spacename = name.."_l"
    namespace[spacename] = lg.newFont(file,l,newhinting,newdpi)
    namespace[spacename]:setFilter("nearest","nearest")
    fontmeta.l = namespace[spacename]
    table.insert(fontmeta,fontmeta.l)
    spacename = name
    namespace[spacename] = lg.newFont(file,n,newhinting,newdpi)
    namespace[spacename]:setFilter("nearest","nearest")
    fontmeta[""] = namespace[spacename]
    table.insert(fontmeta,fontmeta[""])
    spacename = name.."_m"
    namespace[spacename] = lg.newFont(file,m,newhinting,newdpi)
    namespace[spacename]:setFilter("nearest","nearest")
    fontmeta.m = namespace[spacename]
    table.insert(fontmeta,fontmeta.m)
    spacename = name.."_s"
    namespace[spacename] = lg.newFont(file,s,newhinting,newdpi)
    namespace[spacename]:setFilter("nearest","nearest")
    fontmeta.s = namespace[spacename]
    table.insert(fontmeta,fontmeta.s)
    spacename = name.."_xs"
    namespace[spacename] = lg.newFont(file,xs,newhinting,newdpi)
    namespace[spacename]:setFilter("nearest","nearest")
    fontmeta.xs = namespace[spacename]
    table.insert(fontmeta,fontmeta.xs)

    function fontmeta:__call(s)
        if not s then
            return self[math.random(1,#self)]
        end
        return self[s]
    end
    table.insert(namespace.__indices, fontmeta)
end

Font = {}
Font.fonts = {}
Font.fonts.__indices = {}
Font.fonts.default_l     = lg.newFont(36,hinting,dpi)
Font.fonts.default       = lg.newFont(40,hinting,dpi)
Font.fonts.default_s     = lg.newFont(32,hinting,dpi)
Font.fonts.default_xs    = lg.newFont(28,hinting,dpi)
addFont(Font.fonts,'ssp_bold','assets/fonts/SourceSansPro-SemiBold.ttf','mono')
addFont(Font.fonts,'lana','assets/fonts/LanaPixel.ttf',52,48,36,30,24)
addFont(Font.fonts,'compacta','assets/fonts/unicode.compacta.ttf')
addFont(Font.fonts,'pixel','assets/fonts/PublicPixel.ttf',36,32,28,24,20)
addFont(Font.fonts,'azure','assets/fonts/Azure.ttf')
addFont(Font.fonts,'ssp','assets/fonts/SourceSansPro-Light.ttf')
addFont(Font.fonts,'vengeance','assets/fonts/vengeance.ttf',52)
addFont(Font.fonts,'typewrong','assets/fonts/typwrng.ttf')
addFont(Font.fonts,'leorio','assets/fonts/leorio.ttf',52,48,44,36,32,'mono')
addFont(Font.fonts,'openscrawl','assets/fonts/OpenScrawl_v1.ttf',80,hinting,dpi)
addFont(Font.fonts,'fugly', 'assets/fonts/FuglyFont.ttf',52,hinting,dpi)

Font.former = Font.default


function Font.set(f)
    f = f or "default"
    if not Font.fonts[f] then
        _c_warn("Font.set() called with invalid fontname! fontname: "..tostring(f))
        return  --don't set a new font
    end
    Font.former = lg.getFont()
    lg.setFont(Font.fonts[f])
end

function Font.unset()   --quickly return font to previous, like a push/pop scenario
    lg.setFont(Font.former)
end

---@type fun(f?: string)
---@param f? string set font to a valid built font, or leave blank for a random existing font within Font
function Font:__call(f)
    if not f or (type(f)=="string" and #f <= 2) then
        Font.former = lg.getFont()
        local font = Font.fonts.__indices[math.random(1,#Font.fonts.__indices)](f)
        lg.setFont(font)
        return
    end
    Font.set(f)
end

function Font:__tostring()
    return "assetTable"
end

love.graphics.setFont(Font.fonts.default)


