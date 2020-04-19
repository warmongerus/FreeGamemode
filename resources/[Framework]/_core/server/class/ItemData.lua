function API.ItemData(id, name, weight, subTitle)
    local self = {}

    self.id = id
    self.name = name
    self.weight = weight
    self.subTitle = subTitle or "NULL"
    -- self.worldModel = 'default_prop'

    self.getId = function()
        return self.id
    end

    self.getName = function(this)
        return self.name
    end

    self.getSubTitle = function(this)
        return self.subTitle
    end

    self.getWeight = function()
        return self.weight
    end

    -- # Caso queria fazer um ItemDrop com um prop
    --
    -- self.getWorldModel = function()
    --     return self.worldModel
    -- end

    self.onUse = function(this, v)
        self.use = v
    end

    self.use = function(this, User)
        return false
    end

    return self
end