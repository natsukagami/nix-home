#!/usr/bin/env python3

import subprocess
import json

treeP = subprocess.run(["swaymsg", "-t", "get_tree"], stdout=subprocess.PIPE, text=True, check=True)

tree = json.loads(treeP.stdout)

def get_instance(node):
    if 'app_id' in node and node['app_id'] != None:
        return node['app_id']
    elif 'window_properties' in node:
        return node['window_properties']['class']
    return "??"

def get_apps(node):
    if 'pid' in node:
        return [("[%s] %s"%(get_instance(node), node['name']), node['pid'])]
    else:
        return (app for n in node['nodes'] for app in get_apps(n))

apps = dict(get_apps(tree))

keys = '\n'.join(apps.keys())

rofi = subprocess.run(["rofi", "-dmenu", "-i", "-p", "Switch to Window"], stdout=subprocess.PIPE, text=True, check=True, input=keys)

selected = rofi.stdout.strip()

if selected in apps:
    subprocess.run(["swaymsg", "[pid = %d]" % apps[selected], "focus"], check=True)
