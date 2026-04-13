local subPages = {
    {
        name = 'hire',
        label = 'Hire',
        type = 'text',
        content = [[Here you'll be able to hire employees!
        There isn't much here yet...
        
        Soon(tm)]]
    },
    {
        name = 'manage',
        label = 'Manage',
        type = 'text',
        content = [[Heres where you'll fire your employees!
        
        Maybe. Its mostly a second testing subpage.]]
    },
}

return {
    name = 'employees',
    label = 'Employees',
    index = 6,
    subPages = subPages,
}