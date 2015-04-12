parse = (source) ->
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

class Object
    call: (argv) ->
        return {name:'exception', reason:"cannot call #{@repr()}"}

class Interface extends Object
    constructor: (@name, @parent) ->
        @methods = {}
    repr: () -> "#{@name}"

none = new Interface("null")
none.parent = none

class Integer extends Object
    constructor: (@integer) ->
    repr: () -> "#{@integer}"

class String extends Object
    constructor: (@string) ->
    repr: () -> "'#{@string.replace("'", "\\'")}'"

class Closure extends Object
    constructor: (@code) ->
    call: (args) ->
        return {name:'call', callee:@, args}
    repr: () -> "<closure>"

class Native extends Object
    constructor: (@func) ->
    call: (args) ->
        return @func(args)
    repr: () -> "<native>"

class Code
    constructor: (@block) ->
        @top = 1
        for op in @block
            op.i = @top++

class Env
    constructor: () ->
        @block = []

    builder: (exp) -> (op) =>
        @block.push op
        op.start = exp.start
        op.stop = exp.stop
        return op

    close: () ->
        @block.push {name:'return_none'}
        return new Code(@block)

compile = (exps) ->
    env = new Env()
    for exp in exps
        translate(env, exp)
    code = env.close()
    return code

translate = (env, exp) ->
    write = env.builder(exp)
    if exp.name == 'symbol'
        return write name:'variable', value:exp.string
    if exp.name == 'string'
        return write name:'constant', value:new String(exp.string)
    if exp.name == 'int'
        return write name:'constant', value:new Integer(parseInt(exp.string))
    if exp.name == 'hex'
        return write name:'constant', value:new Integer(parseInt(exp.string, 16))
    if exp.name == 'form'
        callee = translate(env, exp.seq[0])
        args = []
        args.push translate(env, arg) for arg in exp.seq[1...]
        return write {name:'call', callee, args}
    throw "compile error: #{exp.name}"

init_state = (code) ->
    block = code.block
    pc = 0
    mem = (none for k in [0...block.top])
    loc = {
        "print": new Native (argv) ->
            console.log (arg.repr() for arg in argv).join(' ')
            return {name:'return', value:none}
    }
    return {block, pc, mem, loc}

interpret = (code) ->
    call_stack = null
    s = init_state(code)
    while s.pc < s.block.length
        op = s.block[s.pc++]
        switch op.name
            when "variable"
                unless s.loc[op.value]?
                    throw "no variable #{op.value}"
                s.mem[op.i] = s.loc[op.value]
            when "constant"
                s.mem[op.i] = op.value
            when "call"
                args = (s.mem[arg.i] for arg in op.args)
                boing = s.mem[op.callee.i].call(args)
                switch boing.name
                    when "call"
                        s.parent = call_stack
                        call_stack = s
                        throw "not implemented"
                    when "return"
                        s.mem[op.i] = boing.value
            when "return_none"
                if call_stack != null
                    s = call_stack
                    call_stack = s.parent
                    throw "not implemented"
                else
                    return none
            else
                throw "unknown op #{op.name}"
    throw "malformed code block"

try_eval = (string) ->
    code = compile(parse(string))
    interpret(code)

window.onload = () ->
    scripts = document.querySelectorAll('script[type="text/kapis"]')
    for script in scripts
        if script.src
            xhr = new XMLHttpRequest()
            xhr.onload = () ->
                try_eval(xhr.response)
            xhr.open("get", script.src, true)
            xhr.send()
        else
            try_eval(script.text)
