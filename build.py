from subprocess import check_output, CalledProcessError
import datetime, os, sys, time

source_directory = 'src'
outfile = "kapis.js"
mtimes = {}

def build():
    output = "window.kapis = {};\n"
    for path in coffee_files():
        mtimes[path] = os.path.getmtime(path)
        output += check_output(['coffee', '-p', path])
    with open(outfile, 'w') as fd:
        fd.write(output)

def watch():
    while True:
        mtime = os.path.getmtime(outfile)
        time.sleep(0.5)
        rebuild = False
        for path in coffee_files():
            mtime = os.path.getmtime(path)
            wtime = mtimes.get(path, mtime-1)
            if wtime < mtime:
                rebuild = True
        if rebuild:
            print "%s: rebuild" % datetime.datetime.utcnow()
            try:
                build()
            except CalledProcessError as error:
                print error

def coffee_files():
    for base, dirs, fils in os.walk(source_directory):
        for filename in fils:
            if filename.endswith('.coffee'):
                yield os.path.join(base, filename)

build()
if len(sys.argv) > 0 and sys.argv[1] in ('-w', '--watch'):
    watch()
