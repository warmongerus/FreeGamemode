Config_Permissions = {
    ["admin"] = {
        type = "staff",
        inheritance = "admin"
    },
    ["moderator"] = {
        type = "staff",
        inheritance = "helper"
    },
    ["helper"] = {
        type = "staff"
    },
    ----------
    ["chief"] = {
        type = "police",
        inheritance = "chief"
    },
    ["soldier"] = {
        type = "police",
        inheritance = "soldier"
    },
    ["recruit"] = {
        type = "police"
    }
}
