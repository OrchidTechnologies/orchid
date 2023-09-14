#  
# e.g.
#
#  +---------+-------------------------------------------+
#  | Package | Dependencies                              |
#  +---------+-------------------------------------------+
#  | l10n    |                                           |
#  | util    | (api.log)                                 |
#  | vpn     | (api.log), api, util                      |
#  | common  | api, orchid, util                         |
#  | api     | (api.log), orchid, util, vpn              |
#  | orchid  | (api.log), api, common, util, vpn         |
#  | pages   | (api.log), api, common, orchid, util, vpn |
#  +---------+-------------------------------------------+
#  

import os
import re

def extract_dependencies0(file_path):
    with open(file_path, 'r') as file:
        content = file.read()
    matches = re.findall(r'import\s+[\'"]package:orchid/(.*?)/', content)
    dependencies = {match.split('/')[0] for match in matches}
    return dependencies



def extract_dependencies(file_path):
    with open(file_path, 'r') as file:
        content = file.read()
    matches = re.findall(r'import\s+[\'"]package:orchid/(.*?)[\'"];', content)
    dependencies = set()
    for match in matches:
        if 'orchid_log.dart' in match:
            dependencies.add('(api.log)')
        else:
            dependencies.add(match.split('/')[0])
    return dependencies



def analyze_package_dependencies(package_path, package_name):
    dependencies = set()
    for root, _, files in os.walk(package_path):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                dependencies |= extract_dependencies(file_path)
    dependencies.discard(package_name)
    return dependencies


def main():
    from prettytable import PrettyTable

    lib_dir = "./lib"  # replace with your lib directory path
    lib_file_list = os.listdir(lib_dir)

    package_dependencies = {
        package: analyze_package_dependencies(os.path.join(lib_dir, package), package)
        for package in lib_file_list
        if os.path.isdir(os.path.join(lib_dir, package))
    }

    table = PrettyTable()
    table.field_names = ["Package", "Dependencies"]
    table.align["Package"] = "l"
    table.align["Dependencies"] = "l"

    for package, dependencies in package_dependencies.items():
        table.add_row([package, ', '.join(sorted(dependencies))])

    print(table)


if __name__ == "__main__":
    main()

