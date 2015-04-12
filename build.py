from subprocess import check_output
import os

output = "window.kapis = {};\n"

for base, dirs, fils in os.walk('src'):
    for filename in fils:
        if filename.endswith('.coffee'):
            path = os.path.join(base, filename)
            output += check_output(['coffee', '-p', path])

with open("kapis.js", 'w') as fd:
    fd.write(output)
