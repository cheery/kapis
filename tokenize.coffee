class CStream
    constructor: (@string) ->
        @index = 0
        @current = @string[@index]
        @lno = 0
        @col = 0

    advance: () ->
        current = @current
        @current = @string[++@index]
        if current == '\n'
            @lno++
            @col = 0
        else
            @col++
        return current

    filled: () -> @index < @string.length

    pos: () -> {lno:@lno, col:@col}

    is_space: () -> @filled() and @current.match /\s/
    is_sym: () -> @filled() and @current.match /\w/
    is_digit: () -> @filled() and @current.match /[0-9]/
    is_hex: () -> @filled() and @current.match /[0-9a-fA-F]/

next_token = (stream, table) ->
    while stream.filled() and stream.is_space()
        stream.advance()
    unless stream.filled()
        return null
    if stream.current == '#'
        while stream.filled() and stream.current != '\n'
            stream.advance()
        return next_token(stream, table)
    start = stream.pos()
    if stream.is_digit()
        string = stream.advance()
        if string == '0' and stream.filled() and stream.current == 'x'
            string += stream.advance()
            while stream.is_hex()
                string += stream.advance()
            return {start, stop:stream.pos(), 'hex', string}
        while stream.is_digit()
            string += stream.advance()
        name = 'int'
        if stream.filled() and stream.current == '.'
            string += stream.advance()
            while stream.is_digit()
                string += stream.advance()
            name = 'float'
        return {start, stop:stream.pos(), name, string}
    if stream.current.match /"|'/
        terminal = stream.advance()
        string = ""
        while stream.filled() and stream.current != terminal
            if stream.current == '\\'
                stream.advance()
            string += stream.advance()
        if stream.advance() != terminal
            throw "nonterminated string"
        return {start, stop:stream.pos(), name:"string", string}
    if table[stream.current]?
        string = stream.advance()
        while stream.filled() and table[string + stream.current]?
            string += stream.advance()
        name = table[string]
        return {start, stop:stream.pos(), name, string}
    if stream.is_sym()
        string = stream.advance()
        while stream.is_sym()
            string += stream.advance()
        name = table[string]
        name ?= 'symbol'
        return {start, stop:stream.pos(), name, string}
    throw "bad character #{stream.current}"

window.tokenize = (source, table) ->
    stream = new CStream(source)
    tokens = []
    while stream.filled()
        res = next_token(stream, table)
        tokens.push res if res?
    return tokens
