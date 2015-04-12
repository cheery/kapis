kapis.compile = (env, exps) ->
    for exp in exps
        translate(env, exp)
    code = env.close()
    return code

translate = (env, exp) ->
    write = env.builder(exp)
    if exp.name == 'symbol'
        return write name:'variable', value:exp.string
    if exp.name == 'string'
        return write name:'constant', value:env.new_string(exp.string)
    if exp.name == 'int'
        return write name:'constant', value:env.new_int(parseInt(exp.string))
    if exp.name == 'hex'
        return write name:'constant', value:env.new_int(parseInt(exp.string, 16))
    if exp.name == 'form'
        callee = translate(env, exp.seq[0])
        args = []
        args.push translate(env, arg) for arg in exp.seq[1...]
        return write {name:'call', callee, args}
    throw "compile error: #{exp.name}"
