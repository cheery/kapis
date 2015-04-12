kapis.parse = (source) ->
    tokens = kapis.tokenize source, {"(": 'lp', ")": 'rp'}
    index = 0
    filled = () -> index < tokens.length
    get = (k=0) -> tokens[index+k]
    advance = () -> tokens[index++]
    expect = (token, name) ->
        throw "syn error" if token.name != name
    expression = () ->
        unless filled()
            throw "syn error"
        if get().name == 'lp'
            lst = []
            lp = advance()
            while get().name != 'rp'
                lst.push expression()
            rp = expect(advance(), 'rp')
            return {start:lp.start, stop:lp.stop, name:'form', seq:lst}
        if get().name == 'rp'
            throw "syn error"
        return advance()
    lst = []
    while filled()
        lst.push expression()
    return lst
